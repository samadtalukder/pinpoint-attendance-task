package com.intelmachin.attendance.ui

import com.intelmachin.attendance.domain.model.LocationStatus
import com.intelmachin.attendance.domain.usecase.CalculateDistanceUseCase
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.domain.usecase.EvaluateAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.MarkAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.SetOfficeLocationUseCase
import com.intelmachin.attendance.fakes.FakeCheckInRepository
import com.intelmachin.attendance.fakes.FakeLocationRepository
import com.intelmachin.attendance.fakes.FakeOfficeRepository
import com.intelmachin.attendance.fakes.OFFICE
import com.intelmachin.attendance.fakes.clockAt
import com.intelmachin.attendance.fakes.fix
import com.intelmachin.attendance.fakes.northOf
import com.intelmachin.attendance.ui.attendance.AttendanceMessage
import com.intelmachin.attendance.ui.attendance.AttendanceUiState
import com.intelmachin.attendance.ui.attendance.AttendanceViewModel
import com.intelmachin.attendance.ui.attendance.LocationAvailability
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AttendanceViewModelTest {
    private val location = FakeLocationRepository()
    private val office = FakeOfficeRepository()
    private val checkIns = FakeCheckInRepository()

    @Before fun setUp() = Dispatchers.setMain(UnconfinedTestDispatcher())
    @After fun tearDown() = Dispatchers.resetMain()

    private fun viewModel(time: String = "09:30"): AttendanceViewModel {
        val clock = clockAt(time)
        val evaluate = EvaluateAttendanceUseCase(CalculateDistanceUseCase(), clock)
        return AttendanceViewModel(
            location, office, checkIns, evaluate,
            SetOfficeLocationUseCase(location, office),
            MarkAttendanceUseCase(location, office, checkIns, evaluate, clock),
        )
    }

    /** Subscribes so the WhileSubscribed upstream is active; returns an accessor for the latest state. */
    private fun TestScope.state(vm: AttendanceViewModel): () -> AttendanceUiState {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { vm.uiState.collect { } }
        return { vm.uiState.value }
    }

    @Test
    fun `initial state is searching with no office`() = runTest {
        val vm = viewModel()
        val s = state(vm)
        assertEquals(LocationAvailability.Searching, s().availability)
        assertEquals(Eligibility.NoOffice, s().eligibility)
        assertFalse(s().canMarkAttendance)
    }

    @Test
    fun `permission denied then permanently denied`() = runTest {
        val vm = viewModel()
        val s = state(vm)
        location.emit(LocationStatus.PermissionDenied)
        assertEquals(LocationAvailability.PermissionDenied, s().availability)
        vm.onPermissionResult(granted = false, canRequestAgain = false)
        assertEquals(LocationAvailability.PermissionPermanentlyDenied, s().availability)
        assertEquals(1, location.refreshCount)
    }

    @Test
    fun `gps off is surfaced`() = runTest {
        val vm = viewModel()
        val s = state(vm)
        location.emit(LocationStatus.GpsOff)
        assertEquals(LocationAvailability.GpsOff, s().availability)
    }

    @Test
    fun `out of range shows distance and locks marking`() = runTest {
        office.save(OFFICE)
        val vm = viewModel()
        val s = state(vm)
        location.emit(LocationStatus.Available(fix(northOf(OFFICE, 120.0))))
        assertEquals(LocationAvailability.Ready, s().availability)
        assertEquals(120.0, s().distanceMeters!!, 1.0)
        assertEquals(false, s().isInRange)
        assertEquals(Eligibility.OutOfRange, s().eligibility)
        assertFalse(s().canMarkAttendance)
    }

    @Test
    fun `in range inside window unlocks marking`() = runTest {
        office.save(OFFICE)
        val vm = viewModel("09:30")
        val s = state(vm)
        location.emit(LocationStatus.Available(fix(northOf(OFFICE, 20.0))))
        assertEquals(true, s().isInRange)
        assertTrue(s().canMarkAttendance)
    }

    @Test
    fun `in range outside window stays locked`() = runTest {
        office.save(OFFICE)
        val vm = viewModel("11:00")
        val s = state(vm)
        location.emit(LocationStatus.Available(fix(OFFICE)))
        assertEquals(true, s().isInRange)
        assertEquals(Eligibility.OutsideWindow, s().eligibility)
        assertFalse(s().canMarkAttendance)
    }

    @Test
    fun `set office saves fix and reports message`() = runTest {
        val vm = viewModel()
        val s = state(vm)
        location.fixResult = fix(OFFICE)
        vm.onSetOfficeLocation()
        assertEquals(OFFICE, s().office)
        assertEquals(AttendanceMessage.OfficeSaved, s().message)
        assertFalse(s().isSettingOffice)
        vm.onMessageShown()
        assertNull(s().message)
    }

    @Test
    fun `set office failure paths keep office unset`() = runTest {
        val vm = viewModel()
        val s = state(vm)
        location.fixResult = null
        vm.onSetOfficeLocation()
        assertEquals(AttendanceMessage.OfficeNoFix, s().message)
        location.fixResult = fix(OFFICE, mock = true)
        vm.onSetOfficeLocation()
        assertEquals(AttendanceMessage.OfficeMockLocation, s().message)
        assertNull(s().office)
    }

    @Test
    fun `mark attendance persists check-in and blocks a second one`() = runTest {
        office.save(OFFICE)
        val vm = viewModel()
        val s = state(vm)
        location.emit(LocationStatus.Available(fix(OFFICE)))
        location.fixResult = fix(OFFICE)
        vm.onMarkAttendance()
        assertEquals(AttendanceMessage.CheckedIn, s().message)
        assertNotNull(s().checkIn)
        assertTrue(s().eligibility is Eligibility.AlreadyCheckedIn)
        assertFalse(s().canMarkAttendance)
    }

    @Test
    fun `mark attendance rejected when fix drifted out of range`() = runTest {
        office.save(OFFICE)
        val vm = viewModel()
        val s = state(vm)
        location.emit(LocationStatus.Available(fix(OFFICE)))
        location.fixResult = fix(northOf(OFFICE, 300.0))
        vm.onMarkAttendance()
        assertEquals(AttendanceMessage.CheckInRejected, s().message)
        assertNull(checkIns.lastCheckIn.first())
    }
}
