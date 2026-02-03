package com.liveplan.data.database.migration

import androidx.room.Room
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.liveplan.data.database.AppDatabase
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.IOException

/**
 * Room migration tests
 *
 * Tests migration paths between schema versions
 */
@RunWith(AndroidJUnit4::class)
class MigrationTest {

    private val TEST_DB_NAME = "migration-test"

    @get:Rule
    val helper: MigrationTestHelper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        AppDatabase::class.java.canonicalName,
        FrameworkSQLiteOpenHelperFactory()
    )

    // ─────────────────────────────────────
    // Migration 1 → 2 Tests
    // ─────────────────────────────────────

    @Test
    @Throws(IOException::class)
    fun migrate1To2() {
        // Create version 1 database
        val db = helper.createDatabase(TEST_DB_NAME, 1).apply {
            // Insert test data in version 1 schema
            execSQL(
                """
                INSERT INTO projects (id, title, startDate, dueDate, note, status, createdAt, updatedAt)
                VALUES ('project-1', 'Test Project', ${System.currentTimeMillis()}, NULL, NULL, 'ACTIVE', ${System.currentTimeMillis()}, ${System.currentTimeMillis()})
                """.trimIndent()
            )

            execSQL(
                """
                INSERT INTO tasks (id, projectId, title, sectionId, tagIdsJson, priority, workflowState, startAt, dueAt, note, recurrenceRuleJson, recurrenceBehavior, nextOccurrenceDueAt, blockedByTaskIdsJson, createdAt, updatedAt)
                VALUES ('task-1', 'project-1', 'Test Task', NULL, '[]', 'P4', 'TODO', NULL, NULL, NULL, NULL, 'HABIT_RESET', NULL, '[]', ${System.currentTimeMillis()}, ${System.currentTimeMillis()})
                """.trimIndent()
            )

            close()
        }

        // Run migration
        helper.runMigrationsAndValidate(TEST_DB_NAME, 2, true, Migrations.MIGRATION_1_2)

        // Verify migration succeeded by opening database at version 2
        val migratedDb = helper.runMigrationsAndValidate(TEST_DB_NAME, 2, true)

        // Query to verify data survived migration
        migratedDb.query("SELECT * FROM projects WHERE id = 'project-1'").use { cursor ->
            assertTrue("Project should exist after migration", cursor.moveToFirst())
            assertEquals("Test Project", cursor.getString(cursor.getColumnIndex("title")))
        }

        migratedDb.query("SELECT * FROM tasks WHERE id = 'task-1'").use { cursor ->
            assertTrue("Task should exist after migration", cursor.moveToFirst())
            assertEquals("Test Task", cursor.getString(cursor.getColumnIndex("title")))
        }

        migratedDb.close()
    }

    @Test
    @Throws(IOException::class)
    fun migrate1To2_nullValuesHandled() {
        // Create version 1 database with null values
        val db = helper.createDatabase(TEST_DB_NAME, 1).apply {
            execSQL(
                """
                INSERT INTO projects (id, title, startDate, dueDate, note, status, createdAt, updatedAt)
                VALUES ('project-1', 'Test Project', ${System.currentTimeMillis()}, NULL, NULL, 'ACTIVE', ${System.currentTimeMillis()}, ${System.currentTimeMillis()})
                """.trimIndent()
            )

            // Insert task with null priority/workflowState (simulating corrupted data)
            execSQL(
                """
                INSERT INTO tasks (id, projectId, title, sectionId, tagIdsJson, priority, workflowState, startAt, dueAt, note, recurrenceRuleJson, recurrenceBehavior, nextOccurrenceDueAt, blockedByTaskIdsJson, createdAt, updatedAt)
                VALUES ('task-null', 'project-1', 'Null Task', NULL, '[]', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', ${System.currentTimeMillis()}, ${System.currentTimeMillis()})
                """.trimIndent()
            )

            close()
        }

        // Run migration - should handle null values
        helper.runMigrationsAndValidate(TEST_DB_NAME, 2, true, Migrations.MIGRATION_1_2)

        // Verify null values were updated to defaults
        val migratedDb = helper.runMigrationsAndValidate(TEST_DB_NAME, 2, true)

        migratedDb.query("SELECT priority, workflowState, recurrenceBehavior FROM tasks WHERE id = 'task-null'").use { cursor ->
            assertTrue("Task should exist after migration", cursor.moveToFirst())
            assertEquals("P4", cursor.getString(cursor.getColumnIndex("priority")))
            assertEquals("TODO", cursor.getString(cursor.getColumnIndex("workflowState")))
            assertEquals("HABIT_RESET", cursor.getString(cursor.getColumnIndex("recurrenceBehavior")))
        }

        migratedDb.close()
    }

    // ─────────────────────────────────────
    // Full Migration Path Test
    // ─────────────────────────────────────

    @Test
    @Throws(IOException::class)
    fun migrateAllVersions() {
        // Create database at initial version
        helper.createDatabase(TEST_DB_NAME, 1).apply {
            execSQL(
                """
                INSERT INTO projects (id, title, startDate, dueDate, note, status, createdAt, updatedAt)
                VALUES ('project-1', 'Test Project', ${System.currentTimeMillis()}, NULL, NULL, 'ACTIVE', ${System.currentTimeMillis()}, ${System.currentTimeMillis()})
                """.trimIndent()
            )
            close()
        }

        // Run all migrations
        val db = Room.databaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java,
            TEST_DB_NAME
        ).addMigrations(*Migrations.ALL).build()

        // Verify database opens successfully at latest version
        db.openHelper.writableDatabase
        db.close()
    }
}
