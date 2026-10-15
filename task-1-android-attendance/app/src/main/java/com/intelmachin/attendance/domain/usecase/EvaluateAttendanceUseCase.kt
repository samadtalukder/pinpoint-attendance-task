package com.intelmachin.attendance.domain.usecase

import com.intelmachin.attendance.domain.AttendancePolicy
import com.intelmachin.attendance.domain.AttendanceRules
import com.intelmachin.attendance.domain.FixProblem
import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.model.LocationFix
import java.time.Clock
import java.time.Instant
import java.time.LocalTime
import javax.inject.Inject

sealed interface Eligibility {
    data object Eligible : Eligibility
    data object NoOffice : Eligibility
    data object NoFix : Eligibility
    data object StaleFix : Eligibility
    data object MockLocation : Eligibility
    data class LowAccuracy(val accuracyMeters: Float) : Eligibility
    data object OutOfRange : Eligibility
    data object OutsideWindow : Eligibility
    data class AlreadyCheckedIn(val checkIn: CheckIn) : Eligibility
}

data class AttendanceCheck(
    val distanceMeters: Double?,
    val eligibility: Eligibility,
    /** True when the last fix is too old to be trusted as the current position. */
    val isStale: Boolean = false,
    /** True while the clock is inside the attendance window, regardless of the other rules. */
    val isWindowOpen: Boolean = true,
) {
    /** Null while distance is unknown (no office or no fix). */
    val isInRange: Boolean? get() = distanceMeters?.let { it <= AttendanceRules.OFFICE_RADIUS_METERS }
}

/** Decides whether attendance may be marked right now. First failing rule wins. */
class EvaluateAttendanceUseCase @Inject constructor(
    private val distance: CalculateDistanceUseCase,
    private val clock: Clock,
    private val policy: AttendancePolicy,
) {
    operator fun invoke(fix: LocationFix?, office: GeoPoint?, lastCheckIn: CheckIn?): AttendanceCheck {
        val meters = if (fix != null && office != null) distance(fix.point, office) else null
        val stale = fix != null && clock.millis() - fix.timeMillis > AttendanceRules.MAX_FIX_AGE_MILLIS
        val windowOpen = isInsideWindow()
        return AttendanceCheck(meters, eligibility(fix, office, meters, stale, windowOpen, lastCheckIn), stale, windowOpen)
    }

    private fun eligibility(
        fix: LocationFix?,
        office: GeoPoint?,
        meters: Double?,
        stale: Boolean,
        windowOpen: Boolean,
        lastCheckIn: CheckIn?,
    ): Eligibility {
        if (lastCheckIn != null && isToday(lastCheckIn)) return Eligibility.AlreadyCheckedIn(lastCheckIn)
        if (office == null) return Eligibility.NoOffice
        if (fix == null || meters == null) return Eligibility.NoFix
        if (stale) return Eligibility.StaleFix
        when (val problem = policy.fixProblem(fix)) {
            FixProblem.MockLocation -> return Eligibility.MockLocation
            is FixProblem.LowAccuracy -> return Eligibility.LowAccuracy(problem.accuracyMeters)
            null -> Unit
        }
        if (meters > AttendanceRules.OFFICE_RADIUS_METERS) return Eligibility.OutOfRange
        if (!windowOpen) return Eligibility.OutsideWindow
        return Eligibility.Eligible
    }

    private fun isToday(checkIn: CheckIn): Boolean {
        val zone = clock.zone
        val day = Instant.ofEpochMilli(checkIn.epochMillis).atZone(zone).toLocalDate()
        return day == clock.instant().atZone(zone).toLocalDate()
    }

    private fun isInsideWindow(): Boolean {
        val now: LocalTime = clock.instant().atZone(clock.zone).toLocalTime()
        return now >= AttendanceRules.WINDOW_START && now <= AttendanceRules.WINDOW_END
    }
}
