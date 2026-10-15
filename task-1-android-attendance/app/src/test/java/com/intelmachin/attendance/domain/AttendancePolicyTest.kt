package com.intelmachin.attendance.domain

import com.intelmachin.attendance.fakes.OFFICE
import com.intelmachin.attendance.fakes.fix
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AttendancePolicyTest {
    private val blocking = AttendancePolicy(blockMockLocations = true)

    @Test
    fun `accuracy boundary - 30 m is trusted, 31 m is not`() {
        assertNull(blocking.fixProblem(fix(OFFICE, accuracy = 30f)))
        assertEquals(FixProblem.LowAccuracy(31f), blocking.fixProblem(fix(OFFICE, accuracy = 31f)))
    }

    @Test
    fun `mock fix is a problem only when blocking is on`() {
        assertEquals(FixProblem.MockLocation, blocking.fixProblem(fix(OFFICE, mock = true)))
        assertNull(AttendancePolicy(blockMockLocations = false).fixProblem(fix(OFFICE, mock = true)))
    }

    @Test
    fun `mock wins over low accuracy`() {
        assertEquals(FixProblem.MockLocation, blocking.fixProblem(fix(OFFICE, accuracy = 80f, mock = true)))
    }
}
