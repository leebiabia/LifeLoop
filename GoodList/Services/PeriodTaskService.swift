import Foundation
import Observation

@Observable
final class PeriodTaskService {
    static func tasksForToday(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let startDate = task.periodStartDate,
                  !task.periodIsCompleted else {
                return false
            }
            return startDate <= Date()
        }
    }

    static func dueTodayTasks(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let endDate = task.periodEndDate,
                  !task.periodIsCompleted else {
                return false
            }
            return Calendar.current.isDateInToday(endDate)
        }
    }

    static func overdueTasks(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let endDate = task.periodEndDate,
                  !task.periodIsCompleted else {
                return false
            }
            return endDate < Date() && !Calendar.current.isDateInToday(endDate)
        }
    }
}
