package com.liveplan.ui.project

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.ui.common.PriorityBadge
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskItem
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Calendar view for tasks
 * Shows monthly calendar with tasks by due date
 */
@Composable
fun CalendarScreen(
    tasks: List<TaskItem>,
    onTaskClick: (TaskItem) -> Unit,
    onToggleComplete: (TaskItem) -> Unit,
    modifier: Modifier = Modifier
) {
    var currentMonth by remember { mutableStateOf(Calendar.getInstance()) }
    var selectedDate by remember { mutableStateOf<Calendar?>(null) }

    // Group tasks by date
    val tasksByDate by remember(tasks) {
        derivedStateOf {
            tasks.filter { it.task.dueAt != null }
                .groupBy { task ->
                    val cal = Calendar.getInstance()
                    cal.timeInMillis = task.task.dueAt!!
                    cal.get(Calendar.YEAR) * 10000 +
                    (cal.get(Calendar.MONTH) + 1) * 100 +
                    cal.get(Calendar.DAY_OF_MONTH)
                }
        }
    }

    // Tasks for selected date
    val selectedDateTasks by remember(selectedDate, tasks) {
        derivedStateOf {
            selectedDate?.let { date ->
                val key = date.get(Calendar.YEAR) * 10000 +
                         (date.get(Calendar.MONTH) + 1) * 100 +
                         date.get(Calendar.DAY_OF_MONTH)
                tasksByDate[key] ?: emptyList()
            } ?: emptyList()
        }
    }

    Column(modifier = modifier.fillMaxSize()) {
        // Calendar header
        CalendarHeader(
            currentMonth = currentMonth,
            onPreviousMonth = {
                currentMonth = (currentMonth.clone() as Calendar).apply {
                    add(Calendar.MONTH, -1)
                }
            },
            onNextMonth = {
                currentMonth = (currentMonth.clone() as Calendar).apply {
                    add(Calendar.MONTH, 1)
                }
            },
            onTodayClick = {
                currentMonth = Calendar.getInstance()
                selectedDate = Calendar.getInstance()
            }
        )

        // Calendar grid
        CalendarGrid(
            currentMonth = currentMonth,
            selectedDate = selectedDate,
            tasksByDate = tasksByDate,
            onDateSelected = { date ->
                selectedDate = date
            }
        )

        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

        // Selected date tasks
        if (selectedDate != null) {
            Text(
                text = formatSelectedDate(selectedDate!!),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            if (selectedDateTasks.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = stringResource(R.string.calendar_no_tasks),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = selectedDateTasks,
                        key = { it.task.id }
                    ) { taskItem ->
                        CalendarTaskCard(
                            taskItem = taskItem,
                            onClick = { onTaskClick(taskItem) },
                            onToggleComplete = { onToggleComplete(taskItem) }
                        )
                    }
                }
            }
        } else {
            // No date selected
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Select a date to see tasks",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun CalendarHeader(
    currentMonth: Calendar,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onTodayClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onPreviousMonth) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = stringResource(R.string.calendar_previous_month)
            )
        }

        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.clickable(onClick = onTodayClick)
        ) {
            Text(
                text = formatMonthYear(currentMonth),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
        }

        IconButton(onClick = onNextMonth) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = stringResource(R.string.calendar_next_month)
            )
        }
    }
}

@Composable
private fun CalendarGrid(
    currentMonth: Calendar,
    selectedDate: Calendar?,
    tasksByDate: Map<Int, List<TaskItem>>,
    onDateSelected: (Calendar) -> Unit,
    modifier: Modifier = Modifier
) {
    val daysOfWeek = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    val today = Calendar.getInstance()

    // Calculate calendar days
    val calendarDays = remember(currentMonth) {
        getCalendarDays(currentMonth)
    }

    Column(modifier = modifier.padding(horizontal = 8.dp)) {
        // Days of week header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            daysOfWeek.forEach { day ->
                Text(
                    text = day,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Calendar days grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.height(240.dp),
            userScrollEnabled = false
        ) {
            items(calendarDays) { day ->
                CalendarDay(
                    day = day,
                    isCurrentMonth = day?.get(Calendar.MONTH) == currentMonth.get(Calendar.MONTH),
                    isToday = day?.let { isSameDay(it, today) } ?: false,
                    isSelected = day?.let { selectedDate?.let { sel -> isSameDay(it, sel) } } ?: false,
                    hasTask = day?.let { d ->
                        val key = d.get(Calendar.YEAR) * 10000 +
                                 (d.get(Calendar.MONTH) + 1) * 100 +
                                 d.get(Calendar.DAY_OF_MONTH)
                        tasksByDate.containsKey(key)
                    } ?: false,
                    taskCount = day?.let { d ->
                        val key = d.get(Calendar.YEAR) * 10000 +
                                 (d.get(Calendar.MONTH) + 1) * 100 +
                                 d.get(Calendar.DAY_OF_MONTH)
                        tasksByDate[key]?.size ?: 0
                    } ?: 0,
                    onClick = { day?.let { onDateSelected(it) } }
                )
            }
        }
    }
}

@Composable
private fun CalendarDay(
    day: Calendar?,
    isCurrentMonth: Boolean,
    isToday: Boolean,
    isSelected: Boolean,
    hasTask: Boolean,
    taskCount: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(
                when {
                    isSelected -> MaterialTheme.colorScheme.primary
                    isToday -> MaterialTheme.colorScheme.primaryContainer
                    else -> Color.Transparent
                }
            )
            .clickable(enabled = day != null, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            day?.let {
                Text(
                    text = it.get(Calendar.DAY_OF_MONTH).toString(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = when {
                        isSelected -> MaterialTheme.colorScheme.onPrimary
                        !isCurrentMonth -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                        else -> MaterialTheme.colorScheme.onSurface
                    },
                    fontWeight = if (isToday || isSelected) FontWeight.Bold else FontWeight.Normal
                )

                if (hasTask && !isSelected) {
                    Box(
                        modifier = Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary)
                    )
                } else if (hasTask && isSelected) {
                    Text(
                        text = "$taskCount",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
        }
    }
}

@Composable
private fun CalendarTaskCard(
    taskItem: TaskItem,
    onClick: () -> Unit,
    onToggleComplete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Circle,
                contentDescription = null,
                modifier = Modifier
                    .size(20.dp)
                    .clickable(onClick = onToggleComplete),
                tint = if (taskItem.isCompleted) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
            )

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = taskItem.task.title,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            if (taskItem.task.priority != Priority.P4) {
                PriorityBadge(priority = taskItem.task.priority)
            }
        }
    }
}

private fun getCalendarDays(month: Calendar): List<Calendar?> {
    val days = mutableListOf<Calendar?>()

    val firstDayOfMonth = (month.clone() as Calendar).apply {
        set(Calendar.DAY_OF_MONTH, 1)
    }
    val lastDayOfMonth = month.getActualMaximum(Calendar.DAY_OF_MONTH)

    // Add padding for days before first day
    val firstDayOfWeek = firstDayOfMonth.get(Calendar.DAY_OF_WEEK)
    repeat(firstDayOfWeek - 1) {
        val prevDay = (firstDayOfMonth.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, -(firstDayOfWeek - 1 - it))
        }
        days.add(prevDay)
    }

    // Add days of month
    for (day in 1..lastDayOfMonth) {
        days.add((month.clone() as Calendar).apply {
            set(Calendar.DAY_OF_MONTH, day)
        })
    }

    // Add padding for days after last day (to fill 6 rows)
    while (days.size < 42) {
        val nextDay = (days.last()!!.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, 1)
        }
        days.add(nextDay)
    }

    return days
}

private fun isSameDay(cal1: Calendar, cal2: Calendar): Boolean {
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
           cal1.get(Calendar.MONTH) == cal2.get(Calendar.MONTH) &&
           cal1.get(Calendar.DAY_OF_MONTH) == cal2.get(Calendar.DAY_OF_MONTH)
}

private fun formatMonthYear(calendar: Calendar): String {
    val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
    return monthFormat.format(calendar.time)
}

private fun formatSelectedDate(calendar: Calendar): String {
    val dateFormat = SimpleDateFormat("EEEE, MMMM d", Locale.getDefault())
    return dateFormat.format(calendar.time)
}

@Preview(showBackground = true)
@Composable
private fun CalendarScreenPreview() {
    LivePlanTheme {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Task due today",
                    priority = Priority.P1,
                    dueAt = System.currentTimeMillis()
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Task due tomorrow",
                    priority = Priority.P2,
                    dueAt = System.currentTimeMillis() + 24 * 60 * 60 * 1000
                ),
                isCompleted = false,
                section = null
            )
        )

        CalendarScreen(
            tasks = tasks,
            onTaskClick = {},
            onToggleComplete = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun CalendarDayPreview() {
    LivePlanTheme {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            CalendarDay(
                day = Calendar.getInstance(),
                isCurrentMonth = true,
                isToday = true,
                isSelected = false,
                hasTask = true,
                taskCount = 3,
                onClick = {},
                modifier = Modifier.size(48.dp)
            )
            CalendarDay(
                day = Calendar.getInstance(),
                isCurrentMonth = true,
                isToday = false,
                isSelected = true,
                hasTask = true,
                taskCount = 2,
                onClick = {},
                modifier = Modifier.size(48.dp)
            )
        }
    }
}
