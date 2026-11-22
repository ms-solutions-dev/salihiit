import ActivityKit
import Core
import Foundation
import os

/// Starts, updates and ends the Live Activity for the running workout.
@MainActor final class IslandController {
    private var activity: Activity<TrainingActivity>?
    private let log = Logger(subsystem: "dev.ms-solutions.salihiit", category: "Island")

    func show(_ run: Timekeeper?) {
        guard let run, !run.ended else {
            end()
            return
        }
        let state = IslandState(run, time: .now)
        // Stale as soon as the phase would have ended without a new state (app fell asleep after all).
        let content = ActivityContent(state: state, staleDate: state.phaseEnd?.addingTimeInterval(2))
        if activity != nil {
            // `Activity` is not Sendable: fetch it fresh in the detached task instead of passing it over.
            Task.detached {
                for a in Activity<TrainingActivity>.activities { await a.update(content) }
            }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity.request(
                attributes: TrainingActivity(template: run.template.name), content: content, pushType: nil)
        } catch {
            log.error("Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func end() {
        // Also clean up leftovers from a crashed run.
        // Only those that exist now: a workout started right afterwards keeps its island.
        let existing = Set(Activity<TrainingActivity>.activities.map(\.id))
        activity = nil
        Task.detached {
            for a in Activity<TrainingActivity>.activities where existing.contains(a.id) {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
