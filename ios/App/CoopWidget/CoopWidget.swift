import WidgetKit
import SwiftUI

/// The ChickenCoops.ai home screen widget: a daily coop tip that changes every morning,
/// and one tap to the coop planner. Works offline: the tips live in this file.

private let paper = Color(red: 0.996, green: 0.965, blue: 0.906)   // #fef6e7
private let ink = Color(red: 0.196, green: 0.106, blue: 0.075)     // #321b13
private let barn = Color(red: 0.812, green: 0.259, blue: 0.220)    // #cf4238
private let sun = Color(red: 0.976, green: 0.835, blue: 0.267)     // #f9d544
private let muted = Color(red: 0.420, green: 0.353, blue: 0.302)   // #6b5a4d

private let plannerURL = URL(string: "https://chickencoops.ai/planner")!
private let homeURL = URL(string: "https://chickencoops.ai/app-home/")!

private let tips: [String] = [
    "Give each hen about 4 square feet inside the coop and 10 in the run.",
    "One nesting box for every 4 hens keeps the peace at laying time.",
    "Roosts should sit higher than nest boxes, or hens will sleep in the boxes.",
    "Good airflow up high and no drafts down low keeps a coop healthy.",
    "Fresh water every day matters more than any treat you can give.",
    "Hardware cloth beats chicken wire for keeping raccoons out.",
    "A dust bath spot helps your flock fight off mites on their own.",
    "Collect eggs at least once a day so they stay clean and fresh.",
    "Crushed oyster shell on the side gives layers strong eggshells.",
    "Lock the coop at dusk. Most predators visit after dark.",
    "Deep litter bedding keeps the coop warm and makes great compost.",
    "New birds should wait two weeks apart before meeting the flock.",
    "Treats should stay under a tenth of what your hens eat each day.",
    "A quick daily look at eyes, combs and droppings catches trouble early."
]

struct CoopEntry: TimelineEntry {
    let date: Date
    let tip: String
}

struct CoopProvider: TimelineProvider {
    private func tip(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return tips[day % tips.count]
    }

    func placeholder(in context: Context) -> CoopEntry {
        CoopEntry(date: Date(), tip: tips[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (CoopEntry) -> Void) {
        completion(CoopEntry(date: Date(), tip: tip(for: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoopEntry>) -> Void) {
        let now = Date()
        let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        completion(Timeline(entries: [CoopEntry(date: now, tip: tip(for: now))], policy: .after(tomorrow)))
    }
}

private extension View {
    @ViewBuilder func coopBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

struct CoopMark: View {
    var size: CGFloat = 14
    var body: some View {
        HStack(spacing: 5) {
            Text("CC")
                .font(.system(size: size * 0.7, weight: .heavy))
                .foregroundColor(paper)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 5).fill(barn))
            Text("Coops AI")
                .font(.system(size: size, weight: .heavy))
                .foregroundColor(ink)
        }
    }
}

struct PlanButton: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "pencil.and.ruler.fill").font(.system(size: 12, weight: .bold))
            Text("Plan a coop").font(.system(size: 13, weight: .heavy))
        }
        .foregroundColor(ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(sun))
    }
}

struct CoopSmallView: View {
    let entry: CoopEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoopMark()
            Text("Daily coop tip")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(barn)
            Text(entry.tip)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ink)
                .lineLimit(5)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(plannerURL)
    }
}

struct CoopMediumView: View {
    let entry: CoopEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CoopMark()
                Spacer(minLength: 0)
                Text("Daily coop tip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(barn)
            }
            Text(entry.tip)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(ink)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Link(destination: plannerURL) { PlanButton() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(homeURL)
    }
}

struct CoopWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CoopEntry
    var body: some View {
        Group {
            if family == .systemMedium {
                CoopMediumView(entry: entry)
            } else {
                CoopSmallView(entry: entry)
            }
        }
        .coopBackground(paper)
    }
}

struct CoopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CoopWidget", provider: CoopProvider()) { entry in
            CoopWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily coop tip")
        .description("A new chicken keeping tip every day, and one tap to the coop planner.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CoopWidgetBundle: WidgetBundle {
    var body: some Widget {
        CoopWidget()
    }
}
