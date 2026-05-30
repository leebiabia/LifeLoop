import Foundation
import Observation

@Observable
final class TodayViewModel {
    var todayTasks: [DoItem] = []
    var completedTodayTasks: [DoItem] = []
    var habits: [DoItem] = []
    var activePeriodTasks: [DoItem] = []
    var dueTodayPeriodTasks: [DoItem] = []
    var overduePeriodTasks: [DoItem] = []

    var completionPercentage: Double {
        let total = todayTasks.count + completedTodayTasks.count
        guard total > 0 else { return 0 }
        return Double(completedTodayTasks.count) / Double(total)
    }

    private let doRepo: DoRepository

    init(doRepo: DoRepository) {
        self.doRepo = doRepo
    }

    func loadData() {
        todayTasks = (try? doRepo.fetchTodayTasks()) ?? []
        completedTodayTasks = (try? doRepo.fetchCompletedTodayTasks()) ?? []
        habits = (try? doRepo.fetchHabits()) ?? []
        let periodTasks = (try? doRepo.fetchActivePeriodTasks()) ?? []
        activePeriodTasks = PeriodTaskService.tasksForToday(from: periodTasks)
        dueTodayPeriodTasks = PeriodTaskService.dueTodayTasks(from: periodTasks)
        overduePeriodTasks = PeriodTaskService.overdueTasks(from: periodTasks)
    }

    func toggleTask(_ item: DoItem) {
        doRepo.toggleComplete(item)
        loadData()
    }

    func recordHabit(_ habit: DoItem) {
        doRepo.recordHabit(habit)
        loadData()
    }
}
