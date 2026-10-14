package com.intelmachin.attendance.ui.attendance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
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
private val SCREEN_PADDING = 16.dp
private val SECTION_SPACING = 20.dp

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
    if (state.availability.blocksScreen) {
        // Nothing else is meaningful without permission or GPS: show only the prompt, centered.
        Box(modifier = modifier.fillMaxSize().padding(SCREEN_PADDING), contentAlignment = Alignment.Center) {
            StatusBanner(state.availability, onGrantPermission, onOpenSettings, onEnableGps)
        }
        return
    }
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()).padding(SCREEN_PADDING),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(SECTION_SPACING),
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

private val PREVIEW_OFFICE = GeoPoint(40.7128, -74.0060)

@Composable
private fun PreviewContent(state: AttendanceUiState) {
    AttendanceTheme {
        AttendanceContent(
            state = state,
            onSetOffice = {}, onMarkAttendance = {}, onGrantPermission = {}, onOpenSettings = {}, onEnableGps = {},
            officeMap = {},
        )
    }
}

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun OutOfRangePreview() = PreviewContent(
    AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = PREVIEW_OFFICE,
        distanceMeters = 120.0,
        isInRange = false,
        eligibility = Eligibility.OutOfRange,
    ),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun InRangeEligiblePreview() = PreviewContent(
    AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = PREVIEW_OFFICE,
        distanceMeters = 12.0,
        isInRange = true,
        eligibility = Eligibility.Eligible,
    ),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun MarkingPreview() = PreviewContent(
    AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = PREVIEW_OFFICE,
        distanceMeters = 12.0,
        isInRange = true,
        eligibility = Eligibility.Eligible,
        isMarking = true,
    ),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun OutsideWindowPreview() = PreviewContent(
    AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = PREVIEW_OFFICE,
        distanceMeters = 12.0,
        isInRange = true,
        eligibility = Eligibility.OutsideWindow,
        isWindowOpen = false,
    ),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun StaleFixPreview() = PreviewContent(
    AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = PREVIEW_OFFICE,
        distanceMeters = 30.0,
        isInRange = true,
        isFixStale = true,
        eligibility = Eligibility.StaleFix,
    ),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun NoOfficePreview() = PreviewContent(
    AttendanceUiState(availability = LocationAvailability.Ready),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun PermissionDeniedPreview() = PreviewContent(
    AttendanceUiState(availability = LocationAvailability.PermissionDenied),
)

@Preview(showBackground = true, heightDp = 900)
@Composable
private fun GpsOffPreview() = PreviewContent(
    AttendanceUiState(availability = LocationAvailability.GpsOff),
)
