package com.intelmachin.attendance.domain

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.usecase.CalculateDistanceUseCase
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.domain.usecase.EvaluateAttendanceUseCase
import com.intelmachin.attendance.fakes.OFFICE
import com.intelmachin.attendance.fakes.clockAt
import com.intelmachin.attendance.fakes.fix
import com.intelmachin.attendance.fakes.northOf
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class EvaluateAttendanceUseCaseTest {
    private fun evaluate(time: String = "09:30") = EvaluateAttendanceUseCase(CalculateDistanceUseCase(), clockAt(time))

    @Test
    fun `eligible when in range, accurate and inside window`() {
        val check = evaluate()(fix(northOf(OFFICE, 10.0)), OFFICE, null)
        assertEquals(Eligibility.Eligible, check.eligibility)
        assertEquals(10.0, check.distanceMeters!!, 1.0)
    }

    @Test
    fun `range boundary - 49 m is in, 51 m is out`() {
        assertEquals(Eligibility.Eligible, evaluate()(fix(northOf(OFFICE, 49.0)), OFFICE, null).eligibility)
        assertEquals(Eligibility.OutOfRange, evaluate()(fix(northOf(OFFICE, 51.0)), OFFICE, null).eligibility)
    }

    @Test
    fun `120 m away is out of range and reports distance`() {
        val check = evaluate()(fix(northOf(OFFICE, 120.0)), OFFICE, null)
        assertEquals(Eligibility.OutOfRange, check.eligibility)
        assertEquals(120.0, check.distanceMeters!!, 1.0)
    }

    @Test
    fun `accuracy boundary - 30 m passes, 31 m fails`() {
        val near = northOf(OFFICE, 5.0)
        assertEquals(Eligibility.Eligible, evaluate()(fix(near, accuracy = 30f), OFFICE, null).eligibility)
        assertEquals(
            Eligibility.LowAccuracy(31f),
            evaluate()(fix(near, accuracy = 31f), OFFICE, null).eligibility,
        )
    }

    @Test
    fun `mock fix is rejected even when in range`() {
        val check = evaluate()(fix(OFFICE, mock = true), OFFICE, null)
        assertEquals(Eligibility.MockLocation, check.eligibility)
    }

    @Test
    fun `window boundaries are inclusive`() {
        for ((time, expected) in listOf(
            "08:59" to Eligibility.OutsideWindow,
            "09:00" to Eligibility.Eligible,
            "10:30" to Eligibility.Eligible,
            "10:31" to Eligibility.OutsideWindow,
        )) {
            assertEquals(time, expected, evaluate(time)(fix(OFFICE, at = time), OFFICE, null).eligibility)
        }
    }

    @Test
    fun `window open flag is reported even when another rule fails first`() {
        val closed = evaluate("16:00")(fix(northOf(OFFICE, 120.0), at = "16:00"), OFFICE, null)
        assertEquals(Eligibility.OutOfRange, closed.eligibility)
        assertEquals(false, closed.isWindowOpen)
        assertEquals(true, evaluate("09:30")(fix(northOf(OFFICE, 120.0)), OFFICE, null).isWindowOpen)
    }

    @Test
    fun `fix older than 15 s is stale and locks even when in range`() {
        // Clock 09:30:00, fix 09:29:40 -> 20 s old.
        val old = fix(OFFICE).copy(timeMillis = Instant.parse("2026-10-12T09:29:40Z").toEpochMilli())
        val check = evaluate()(old, OFFICE, null)
        assertEquals(Eligibility.StaleFix, check.eligibility)
        assertTrue(check.isStale)
        assertNotNull(check.distanceMeters)
    }

    @Test
    fun `fix exactly 15 s old still counts as live`() {
        val edge = fix(OFFICE).copy(timeMillis = Instant.parse("2026-10-12T09:29:45Z").toEpochMilli())
        val check = evaluate()(edge, OFFICE, null)
        assertEquals(Eligibility.Eligible, check.eligibility)
        assertEquals(false, check.isStale)
    }

    @Test
    fun `no office and no fix`() {
        assertEquals(Eligibility.NoOffice, evaluate()(fix(OFFICE), null, null).eligibility)
        val noFix = evaluate()(null, OFFICE, null)
        assertEquals(Eligibility.NoFix, noFix.eligibility)
        assertNull(noFix.distanceMeters)
    }

    @Test
    fun `already checked in today blocks, yesterday does not`() {
        val today = CheckIn(Instant.parse("2026-10-12T09:05:00Z").toEpochMilli())
        val yesterday = CheckIn(Instant.parse("2026-10-11T09:05:00Z").toEpochMilli())
        val f = fix(OFFICE)
        val blocked = evaluate()(f, OFFICE, today).eligibility
        assertTrue(blocked is Eligibility.AlreadyCheckedIn)
        assertNotNull((blocked as Eligibility.AlreadyCheckedIn).checkIn)
        assertEquals(Eligibility.Eligible, evaluate()(f, OFFICE, yesterday).eligibility)
    }
}
