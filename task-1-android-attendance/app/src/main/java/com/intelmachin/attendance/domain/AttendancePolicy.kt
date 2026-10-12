package com.intelmachin.attendance.domain

/** Switchable rules, separate from the fixed [AttendanceRules] so tests can exercise both settings. */
data class AttendancePolicy(
    val blockMockLocations: Boolean = AttendanceRules.BLOCK_MOCK_LOCATIONS,
)
