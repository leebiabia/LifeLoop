import Foundation
import Observation

@Observable
final class GoalViewModel {
    var goals: [GoalItem] = []
    var completedGoals: [GoalItem] = []

    private let goalRepo: GoalRepository

    init(goalRepo: GoalRepository) {
        self.goalRepo = goalRepo
    }

    func loadData() {
        goals = (try? goalRepo.fetchActive()) ?? []
        completedGoals = (try? goalRepo.fetchCompleted()) ?? []
    }

    func createProgressGoal(name: String, desc: String, target: Double, unit: String, color: String) {
        goalRepo.createProgressGoal(name: name, desc: desc, targetValue: target, unit: unit, color: color)
        loadData()
    }

    func createAccumulationGoal(name: String, desc: String, target: Double, unit: String, color: String) {
        goalRepo.createAccumulationGoal(name: name, desc: desc, targetValue: target, unit: unit, color: color)
        loadData()
    }

    func createLifetimeGoal(name: String, desc: String, color: String) {
        goalRepo.createLifetimeGoal(name: name, desc: desc, color: color)
        loadData()
    }

    func addRecord(to goal: GoalItem, value: Double = 1, note: String = "") {
        goalRepo.addRecord(to: goal, value: value, note: note)
        loadData()
    }

    func deleteGoal(_ goal: GoalItem) {
        goalRepo.delete(goal)
        loadData()
    }
}
