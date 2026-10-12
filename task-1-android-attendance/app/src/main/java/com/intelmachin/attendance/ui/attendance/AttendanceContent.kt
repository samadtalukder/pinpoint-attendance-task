package com.intelmachin.attendance.ui.attendance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.ui.attendance.components.DistanceRing
import com.intelmachin.attendance.ui.attendance.components.MarkAttendanceCard
import com.intelmachin.attendance.ui.attendance.components.OfficeContextCard
import com.intelmachin.attendance.ui.attendance.components.OfficeMap
import com.intelmachin.attendance.ui.attendance.components.RangeStatusSection
import com.intelmachin.attendance.ui.attendance.components.StatusBanner
import com.intelmachin.attendance.ui.theme.AttendanceTheme

private val MAP_HEIGHT = 140.dp

/** Stateless: renders [state] and reports intents. No rules live here. */
@Composable
fun AttendanceContent(
    state: AttendanceUiState,
    onSetOffice: () -> Unit,
    onMarkAttendance: () -> Unit,
    onGrantPermission: () -> Unit,
    onOpenSettings: () -> Unit,
    onEnableGps: () -> Unit,
    modifier: Modifier = Modifier,
    officeMap: @Composable (GeoPoint) -> Unit = { OfficeMap(it, Modifier.fillMaxWidth().height(MAP_HEIGHT)) },
) {
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()).padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        StatusBanner(state.availability, onGrantPermission, onOpenSettings, onEnableGps)
        OfficeContextCard(
            office = state.office,
            isSettingOffice = state.isSettingOffice,
            canSetOffice = state.availability == LocationAvailability.Ready,
            onSetOffice = onSetOffice,
            map = officeMap,
        )
        DistanceRing(state.distanceMeters, state.isInRange)
        RangeStatusSection(state.distanceMeters, state.isInRange, state.isFixStale)
        MarkAttendanceCard(state.eligibility, state.isWindowOpen, state.isMarking, onMarkAttendance)
    }
}

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun OutOfRangePreview() {
    AttendanceTheme {
        AttendanceContent(
            state = AttendanceUiState(
                availability = LocationAvailability.Ready,
                office = GeoPoint(40.7128, -74.0060),
                distanceMeters = 120.0,
                isInRange = false,
                eligibility = Eligibility.OutOfRange,
            ),
            onSetOffice = {}, onMarkAttendance = {}, onGrantPermission = {}, onOpenSettings = {}, onEnableGps = {},
            officeMap = {},
        )
    }
}
