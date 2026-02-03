package com.liveplan.core.privacy

import com.liveplan.core.model.PrivacyMode
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Tests for PrivacyMasker
 * Covers: Level 0/1/2 masking rules for titles and project names
 */
class PrivacyMaskerTest {

    private lateinit var masker: PrivacyMasker

    @Before
    fun setUp() {
        masker = PrivacyMasker()
    }

    // ─────────────────────────────────────
    // B7: Privacy Mode Level 0 (Full Title)
    // ─────────────────────────────────────

    @Test
    fun `Level 0 - short title shown in full`() {
        val title = "Buy groceries"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_0)

        assertEquals("Buy groceries", result)
    }

    @Test
    fun `Level 0 - long title truncated with ellipsis`() {
        val title = "This is a very long task title that exceeds the maximum length"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_0)

        assertTrue(result.length <= 24)
        assertTrue(result.endsWith("…"))
    }

    @Test
    fun `Level 0 - title exactly at max length shown in full`() {
        val title = "123456789012345678901234" // 24 chars

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_0)

        assertEquals(title, result)
    }

    @Test
    fun `Level 0 - project name shown in full`() {
        val name = "Work Project"

        val result = masker.maskProjectName(name, PrivacyMode.LEVEL_0)

        assertEquals("Work Project", result)
    }

    // ─────────────────────────────────────
    // B7: Privacy Mode Level 1 (Masked)
    // ─────────────────────────────────────

    @Test
    fun `Level 1 - title with index shows anonymous form`() {
        val title = "Secret task"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 1)

        assertEquals("할 일 1", result)
    }

    @Test
    fun `Level 1 - title with index 2`() {
        val title = "Another secret task"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 2)

        assertEquals("할 일 2", result)
    }

    @Test
    fun `Level 1 - title without index shows abbreviated form`() {
        val title = "Secret task"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // Should show first 3 chars + ***
        assertEquals("Sec***", result)
    }

    @Test
    fun `Level 1 - short title without index`() {
        val title = "Hi"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // Short title just shown as-is
        assertEquals("Hi", result)
    }

    @Test
    fun `Level 1 - project name hidden`() {
        val name = "Secret Project"

        val result = masker.maskProjectName(name, PrivacyMode.LEVEL_1)

        assertEquals("프로젝트", result)
    }

    // ─────────────────────────────────────
    // B7: Privacy Mode Level 2 (Count Only)
    // ─────────────────────────────────────

    @Test
    fun `Level 2 - title returns empty string`() {
        val title = "Secret task"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_2)

        assertEquals("", result)
    }

    @Test
    fun `Level 2 - title with index still returns empty`() {
        val title = "Secret task"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_2, index = 1)

        assertEquals("", result)
    }

    @Test
    fun `Level 2 - project name returns empty string`() {
        val name = "Secret Project"

        val result = masker.maskProjectName(name, PrivacyMode.LEVEL_2)

        assertEquals("", result)
    }

    // ─────────────────────────────────────
    // Edge Cases
    // ─────────────────────────────────────

    @Test
    fun `empty title handled correctly at all levels`() {
        val empty = ""

        assertEquals("", masker.maskTitle(empty, PrivacyMode.LEVEL_0))
        assertEquals("", masker.maskTitle(empty, PrivacyMode.LEVEL_1))
        assertEquals("", masker.maskTitle(empty, PrivacyMode.LEVEL_2))
    }

    @Test
    fun `Korean title masked correctly at Level 1`() {
        val title = "비밀 업무"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // First 3 chars + ***
        assertEquals("비밀 ***", result)
    }

    @Test
    fun `mixed language title masked correctly`() {
        val title = "업무 Meeting"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        assertEquals("업무 ***", result)
    }

    @Test
    fun `single character title at Level 1`() {
        val title = "A"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // Too short to abbreviate
        assertEquals("A", result)
    }

    @Test
    fun `three character title at Level 1`() {
        val title = "ABC"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // Exactly at visible chars limit
        assertEquals("ABC", result)
    }

    @Test
    fun `four character title at Level 1`() {
        val title = "ABCD"

        val result = masker.maskTitle(title, PrivacyMode.LEVEL_1)

        // Should abbreviate
        assertEquals("ABC***", result)
    }

    // ─────────────────────────────────────
    // Default Privacy Mode
    // ─────────────────────────────────────

    @Test
    fun `default privacy mode is LEVEL_1`() {
        assertEquals(PrivacyMode.LEVEL_1, PrivacyMode.DEFAULT)
    }

    // ─────────────────────────────────────
    // Consistency Tests
    // ─────────────────────────────────────

    @Test
    fun `same input same privacy mode gives consistent output`() {
        val title = "Consistent task"

        val result1 = masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 1)
        val result2 = masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 1)

        assertEquals(result1, result2)
    }

    @Test
    fun `multiple calls with different indices`() {
        val title = "Task"

        assertEquals("할 일 1", masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 1))
        assertEquals("할 일 2", masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 2))
        assertEquals("할 일 3", masker.maskTitle(title, PrivacyMode.LEVEL_1, index = 3))
    }
}
