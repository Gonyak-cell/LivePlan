package com.liveplan.widget

import com.google.common.truth.Truth.assertThat
import com.liveplan.widget.ui.WidgetTheme
import org.junit.Test

/**
 * Tests for WidgetTheme design tokens
 */
class WidgetThemeTest {

    @Test
    fun `colors are valid hex values`() {
        // Verify all color values are valid integers
        assertThat(WidgetTheme.Colors.background).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.backgroundVariant).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.primary).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.textPrimary).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.textSecondary).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.textMuted).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.overdue).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.dueSoon).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.doing).isNotEqualTo(0)
        assertThat(WidgetTheme.Colors.p1).isNotEqualTo(0)
    }

    @Test
    fun `spacing values are positive`() {
        assertThat(WidgetTheme.paddingSmall.value).isGreaterThan(0f)
        assertThat(WidgetTheme.paddingMedium.value).isGreaterThan(0f)
        assertThat(WidgetTheme.paddingLarge.value).isGreaterThan(0f)
    }

    @Test
    fun `font sizes are positive`() {
        assertThat(WidgetTheme.fontSizeTitle.value).isGreaterThan(0f)
        assertThat(WidgetTheme.fontSizeBody.value).isGreaterThan(0f)
        assertThat(WidgetTheme.fontSizeCounter.value).isGreaterThan(0f)
        assertThat(WidgetTheme.fontSizeLarge.value).isGreaterThan(0f)
    }

    @Test
    fun `corner radius is positive`() {
        assertThat(WidgetTheme.cornerRadius.value).isGreaterThan(0f)
    }

    @Test
    fun `overdue color is distinct from primary`() {
        assertThat(WidgetTheme.Colors.overdue).isNotEqualTo(WidgetTheme.Colors.primary)
    }

    @Test
    fun `dueSoon color is distinct from overdue`() {
        assertThat(WidgetTheme.Colors.dueSoon).isNotEqualTo(WidgetTheme.Colors.overdue)
    }
}
