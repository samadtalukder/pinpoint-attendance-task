package com.intelmachin.attendance.domain

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.AttendancePolicy
import com.intelmachin.attendance.domain.usecase.CalculateDistanceUseCase
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.domain.usecase.EvaluateAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.MarkAttendanceResult
import com.intelmachin.attendance.domain.usecase.MarkAttendanceUseCase
import com.intelmachin.attendance.domain.usecase.SetOfficeLocationUseCase
import com.intelmachin.attendance.domain.usecase.SetOfficeResult
import com.intelmachin.attendance.fakes.FakeCheckInRepository
import com.intelmachin.attendance.fakes.FakeLocationRepository
import com.intelmachin.attendance.fakes.FakeOfficeRepository
import com.intelmachin.attendance.fakes.OFFICE
import com.intelmachin.attendance.fakes.clockAt
import com.intelmachin.attendance.fakes.fix
import com.intelmachin.attendance.fakes.northOf
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SetOfficeLocationUseCaseTest {
    private val location = FakeLocationRepository()
    private val office = FakeOfficeRepository()
    private val setOffice = SetOfficeLocationUseCase(location, office, AttendancePolicy(blockMockLocations = true))

    @Test
    fun `saves good fix`() = runTest {
        location.fixResult = fix(OFFICE, accuracy = 8f)
        assertEquals(SetOfficeResult.Saved(OFFICE), setOffice())
        assertEquals(OFFICE, office.office.first())
    }

    @Test
    fun `mock fix is saved when blocking is off`() = runTest {
        location.fixResult = fix(OFFICE, mock = true)
        assertEquals(SetOfficeResult.Saved(OFFICE), SetOfficeLocationUseCase(location, office, AttendancePolicy())())
    }

    @Test
    fun `can be re-set to a new location`() = runTest {
        location.fixResult = fix(OFFICE)
        setOffice()
        val moved = northOf(OFFICE, 500.0)
        location.fixResult = fix(moved)
        setOffice()
        assertEquals(moved, office.office.first())
    }

    @Test
    fun `rejects missing, mock and inaccurate fixes without saving`() = runTest {
        location.fixResult = null
        assertEquals(SetOfficeResult.NoFix, setOffice())
        location.fixResult = fix(OFFICE, mock = true)
        assertEquals(SetOfficeResult.MockLocation, setOffice())
        location.fixResult = fix(OFFICE, accuracy = 80f)
        assertEquals(SetOfficeResult.LowAccuracy(80f), setOffice())
        assertNull(office.office.first())
    }
}

class MarkAttendanceUseCaseTest {
    private val location = FakeLocationRepository()
    private val office = FakeOfficeRepository(OFFICE)
    private val checkIns = FakeCheckInRepository()
    private val clock = clockAt("09:15")
    private val mark = MarkAttendanceUseCase(
        location, office, checkIns, EvaluateAttendanceUseCase(CalculateDistanceUseCase(), clock, AttendancePolicy()), clock,
    )

    @Test
    fun `marks and persists when eligible`() = runTest {
        location.fixResult = fix(northOf(OFFICE, 20.0))
        val result = mark()
        assertEquals(MarkAttendanceResult.Marked(CheckIn(clock.millis())), result)
        assertEquals(CheckIn(clock.millis()), checkIns.lastCheckIn.first())
    }

    @Test
    fun `rejects when out of range and stores nothing`() = runTest {
        location.fixResult = fix(northOf(OFFICE, 200.0))
        assertEquals(MarkAttendanceResult.Rejected(Eligibility.OutOfRange), mark())
        assertNull(checkIns.lastCheckIn.first())
    }

    @Test
    fun `second attempt same day is rejected`() = runTest {
        location.fixResult = fix(OFFICE)
        mark()
        assertEquals(
            MarkAttendanceResult.Rejected(Eligibility.AlreadyCheckedIn(CheckIn(clock.millis()))),
            mark(),
        )
    }
}
