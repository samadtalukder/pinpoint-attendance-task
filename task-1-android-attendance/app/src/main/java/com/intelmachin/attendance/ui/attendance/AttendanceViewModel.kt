package com.intelmachin.attendance.ui.attendance

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.intelmachin.attendance.domain.model.LocationStatus
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.GpsSettingsChecker
import com.intelmachin.attendance.domain.repository.GpsSettingsResult
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import com.intelmachin.attendance.domain.usecase.EvaluateAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.MarkAttendanceResult
import com.intelmachin.attendance.domain.usecase.MarkAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.SetOfficeLocationUseCase
import com.intelmachin.attendance.domain.usecase.SetOfficeResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Orchestrates repositories and use cases into one [AttendanceUiState]. Holds no business rules. */
@HiltViewModel
class AttendanceViewModel @Inject constructor(
    private val location: LocationRepository,
    office: OfficeRepository,
    checkIns: CheckInRepository,
    private val evaluate: EvaluateAttendanceUseCase,
    private val setOfficeLocation: SetOfficeLocationUseCase,
    private val markAttendance: MarkAttendanceUseCase,
    private val gpsSettings: GpsSettingsChecker,
) : ViewModel() {

    private data class Local(
        val permissionPermanentlyDenied: Boolean = false,
        val isSettingOffice: Boolean = false,
        val isMarking: Boolean = false,
        val message: AttendanceMessage? = null,
    )

    private val local = MutableStateFlow(Local())

    private val eventChannel = Channel<AttendanceEvent>(Channel.BUFFERED)

    /** One-shot platform actions the screen must perform, each delivered once. */
    val events: Flow<AttendanceEvent> = eventChannel.receiveAsFlow()

    /** Re-evaluates time-based rules (window, fix age) while the screen stays open. */
    private val clockTick = flow {
        while (true) {
            emit(Unit)
            delay(CLOCK_TICK_MS)
        }
    }

    val uiState: StateFlow<AttendanceUiState> = combine(
        location.status, office.office, checkIns.lastCheckIn, local, clockTick,
    ) { status, officePoint, lastCheckIn, localState, _ ->
        val fix = (status as? LocationStatus.Available)?.fix
        val check = evaluate(fix, officePoint, lastCheckIn)
        AttendanceUiState(
            availability = when (status) {
                LocationStatus.PermissionDenied ->
                    if (localState.permissionPermanentlyDenied) LocationAvailability.PermissionPermanentlyDenied
                    else LocationAvailability.PermissionDenied
                LocationStatus.ApproximateOnly ->
                    if (localState.permissionPermanentlyDenied) LocationAvailability.PermissionPermanentlyDenied
                    else LocationAvailability.PreciseLocationNeeded
                LocationStatus.GpsOff -> LocationAvailability.GpsOff
                LocationStatus.Searching -> LocationAvailability.Searching
                is LocationStatus.Available -> LocationAvailability.Ready
            },
            office = officePoint,
            distanceMeters = check.distanceMeters,
            isInRange = check.isInRange,
            isFixStale = check.isStale,
            eligibility = check.eligibility,
            isWindowOpen = check.isWindowOpen,
            checkIn = lastCheckIn,
            isSettingOffice = localState.isSettingOffice,
            isMarking = localState.isMarking,
            message = localState.message,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT_MS), AttendanceUiState())

    /** Call after the runtime permission dialog closes. */
    fun onPermissionResult(granted: Boolean, canRequestAgain: Boolean) {
        local.update { it.copy(permissionPermanentlyDenied = !granted && !canRequestAgain) }
        location.refresh()
    }

    /** Call when the screen returns to the foreground, e.g. after app settings or GPS settings. */
    fun onScreenResumed() = location.refresh()

    fun onEnableGps() {
        viewModelScope.launch {
            when (val result = gpsSettings.check()) {
                GpsSettingsResult.AlreadyOn -> location.refresh()
                is GpsSettingsResult.NeedsResolution -> eventChannel.send(AttendanceEvent.ResolveGps(result.resolution))
                GpsSettingsResult.Unavailable -> eventChannel.send(AttendanceEvent.OpenLocationSettings)
            }
        }
    }

    fun onSetOfficeLocation() = runAction(
        isBusy = local.value.isSettingOffice,
        setBusy = { copy(isSettingOffice = it) },
    ) {
        when (setOfficeLocation()) {
            is SetOfficeResult.Saved -> AttendanceMessage.OfficeSaved
            SetOfficeResult.NoFix -> AttendanceMessage.OfficeNoFix
            SetOfficeResult.MockLocation -> AttendanceMessage.OfficeMockLocation
            is SetOfficeResult.LowAccuracy -> AttendanceMessage.OfficeLowAccuracy
        }
    }

    fun onMarkAttendance() = runAction(
        isBusy = local.value.isMarking,
        setBusy = { copy(isMarking = it) },
    ) {
        when (markAttendance()) {
            is MarkAttendanceResult.Marked -> AttendanceMessage.CheckedIn
            is MarkAttendanceResult.Rejected -> AttendanceMessage.CheckInRejected
        }
    }

    /**
     * Runs [action] behind a busy flag and reports its message. A failing GPS read or storage write
     * must not leave the flag stuck or crash the app, so it becomes [AttendanceMessage.ActionFailed].
     */
    private fun runAction(
        isBusy: Boolean,
        setBusy: Local.(Boolean) -> Local,
        action: suspend () -> AttendanceMessage,
    ) {
        if (isBusy) return
        viewModelScope.launch {
            local.update { it.setBusy(true) }
            val message = try {
                action()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Attendance action failed", e)
                AttendanceMessage.ActionFailed
            }
            local.update { it.setBusy(false).copy(message = message) }
        }
    }

    fun onMessageShown() = local.update { it.copy(message = null) }

    private companion object {
        const val TAG = "AttendanceViewModel"
        const val CLOCK_TICK_MS = 5_000L
        const val STOP_TIMEOUT_MS = 5_000L
    }
}
