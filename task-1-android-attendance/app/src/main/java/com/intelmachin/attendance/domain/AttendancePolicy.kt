package com.intelmachin.attendance.domain

import com.intelmachin.attendance.domain.model.LocationFix

/** Why a GPS fix cannot be trusted for any rule that uses a position. */
sealed interface FixProblem {
    data object MockLocation : FixProblem
    data class LowAccuracy(val accuracyMeters: Float) : FixProblem
}

/** Switchable rules, separate from the fixed [AttendanceRules] so tests can exercise both settings. */
data class AttendancePolicy(
    val blockMockLocations: Boolean = AttendanceRules.BLOCK_MOCK_LOCATIONS,
) {
    /** Single source of truth for fix trust, shared by setting the office and marking attendance. */
    fun fixProblem(fix: LocationFix): FixProblem? = when {
        fix.isMock && blockMockLocations -> FixProblem.MockLocation
        fix.accuracyMeters > AttendanceRules.MAX_ACCURACY_METERS -> FixProblem.LowAccuracy(fix.accuracyMeters)
        else -> null
    }
}
