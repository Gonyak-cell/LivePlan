package com.liveplan.data.database.dao

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.entity.TagEntity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Room DAO tests for TagDao
 */
@RunWith(AndroidJUnit4::class)
class TagDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var tagDao: TagDao

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        tagDao = database.tagDao()
    }

    @After
    fun tearDown() {
        database.close()
    }

    // ─────────────────────────────────────
    // Insert / Get Tests
    // ─────────────────────────────────────

    @Test
    fun insertAndGetById() = runBlocking {
        val tag = createTag("tag-1", "Work", "blue")
        tagDao.insert(tag)

        val loaded = tagDao.getTagById("tag-1")

        assertNotNull(loaded)
        assertEquals("tag-1", loaded?.id)
        assertEquals("Work", loaded?.name)
        assertEquals("blue", loaded?.colorToken)
    }

    @Test
    fun getAllTags() = runBlocking {
        val tag1 = createTag("tag-1", "Work", "blue")
        val tag2 = createTag("tag-2", "Personal", "green")
        val tag3 = createTag("tag-3", "Urgent", "red")
        tagDao.insert(tag1)
        tagDao.insert(tag2)
        tagDao.insert(tag3)

        val tags = tagDao.getAllTags().first()

        assertEquals(3, tags.size)
    }

    // ─────────────────────────────────────
    // Get By Name (Case-Insensitive)
    // ─────────────────────────────────────

    @Test
    fun getByNameExactMatch() = runBlocking {
        val tag = createTag("tag-1", "Work", "blue")
        tagDao.insert(tag)

        val loaded = tagDao.getTagByName("Work")

        assertNotNull(loaded)
        assertEquals("tag-1", loaded?.id)
    }

    @Test
    fun getByNameCaseInsensitive() = runBlocking {
        val tag = createTag("tag-1", "Work", "blue")
        tagDao.insert(tag)

        val loadedLower = tagDao.getTagByName("work")
        val loadedUpper = tagDao.getTagByName("WORK")
        val loadedMixed = tagDao.getTagByName("WoRk")

        assertNotNull(loadedLower)
        assertNotNull(loadedUpper)
        assertNotNull(loadedMixed)
        assertEquals("tag-1", loadedLower?.id)
        assertEquals("tag-1", loadedUpper?.id)
        assertEquals("tag-1", loadedMixed?.id)
    }

    @Test
    fun getByNameNotFound() = runBlocking {
        val loaded = tagDao.getTagByName("NonExistent")

        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Update Tests
    // ─────────────────────────────────────

    @Test
    fun updateTag() = runBlocking {
        val tag = createTag("tag-1", "Work", "blue")
        tagDao.insert(tag)

        val updated = tag.copy(name = "Office", colorToken = "purple")
        tagDao.update(updated)

        val loaded = tagDao.getTagById("tag-1")
        assertEquals("Office", loaded?.name)
        assertEquals("purple", loaded?.colorToken)
    }

    // ─────────────────────────────────────
    // Delete Tests
    // ─────────────────────────────────────

    @Test
    fun deleteById() = runBlocking {
        val tag = createTag("tag-1", "Work", "blue")
        tagDao.insert(tag)

        tagDao.deleteById("tag-1")

        val loaded = tagDao.getTagById("tag-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Ordering Tests
    // ─────────────────────────────────────

    @Test
    fun tagsOrderedByName() = runBlocking {
        tagDao.insert(createTag("tag-3", "Zebra", null))
        tagDao.insert(createTag("tag-1", "Alpha", null))
        tagDao.insert(createTag("tag-2", "Beta", null))

        val tags = tagDao.getAllTags().first()

        assertEquals(3, tags.size)
        assertEquals("Alpha", tags[0].name)
        assertEquals("Beta", tags[1].name)
        assertEquals("Zebra", tags[2].name)
    }

    // ─────────────────────────────────────
    // Nullable ColorToken Tests
    // ─────────────────────────────────────

    @Test
    fun tagWithNullColorToken() = runBlocking {
        val tag = createTag("tag-1", "Work", null)
        tagDao.insert(tag)

        val loaded = tagDao.getTagById("tag-1")

        assertNotNull(loaded)
        assertNull(loaded?.colorToken)
    }

    // ─────────────────────────────────────
    // Round-trip Test
    // ─────────────────────────────────────

    @Test
    fun roundTripAllFields() = runBlocking {
        val tag = TagEntity(
            id = "tag-full",
            name = "Full Tag",
            colorToken = "gradient-rainbow"
        )
        tagDao.insert(tag)

        val loaded = tagDao.getTagById("tag-full")

        assertNotNull(loaded)
        assertEquals(tag.id, loaded?.id)
        assertEquals(tag.name, loaded?.name)
        assertEquals(tag.colorToken, loaded?.colorToken)
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createTag(id: String, name: String, colorToken: String?): TagEntity {
        return TagEntity(
            id = id,
            name = name,
            colorToken = colorToken
        )
    }
}
