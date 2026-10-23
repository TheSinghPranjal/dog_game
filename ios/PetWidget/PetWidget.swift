import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Shared data

private enum Pen {
  static let ink = Color(red: 0x22 / 255, green: 0x36 / 255, blue: 0xB5 / 255)
  static let inkSoft = Color(red: 0x6E / 255, green: 0x86 / 255, blue: 0xDD / 255)
  static let pencil = Color(red: 0x26 / 255, green: 0x26 / 255, blue: 0x2B / 255)
  static let paper = Color(red: 0xFC / 255, green: 0xFB / 255, blue: 0xF6 / 255)
  static let coralLight = Color(red: 0xFB / 255, green: 0xD9 / 255, blue: 0xD2 / 255)
}

/// Must match AppLaunchRouter.widgetLink in Dart.
private let launchURL = URL(string: "mypetdog://game/home?source=widget")!

/// The payload the app writes when the player leaves the game (see
/// PetWidgetPayload in Dart). Missing or newer-schema data falls back to
/// defaults, so the widget always renders.
private struct PetPayload {
  static let appGroup = "group.com.thelazybearClub.myPetDog"
  static let schemaVersion = 1

  /// Set by WoofIntent when the puppy is tapped (widget-only, not from Dart).
  static let woofKey = "woofRequestedAt"

  var pose = "idle"
  var lastInteraction: String?
  var woofRequestedAt: Date?

  static func load() -> PetPayload {
    guard let defaults = UserDefaults(suiteName: appGroup) else { return PetPayload() }
    let woof = defaults.object(forKey: woofKey) as? Date
    guard defaults.integer(forKey: "schemaVersion") <= schemaVersion
    else { return PetPayload(woofRequestedAt: woof) }
    return PetPayload(
      pose: defaults.string(forKey: "pose") ?? "idle",
      lastInteraction: defaults.string(forKey: "lastInteraction"),
      woofRequestedAt: woof
    )
  }
}

// MARK: - Routine

/// One beat of the puppy's routine: which pose image, where along the floor
/// (0 = her spot, 1 = at her ball), which way she faces, whether she is
/// saying "Woof!", and how long the beat lasts.
///
/// The same routine as the Android flip-book (tool/widget_assets/widget_routine.dart),
/// at WidgetKit's pace: iOS shows timeline entries rather than running the
/// widget, and animates the change between entries (iOS 17+), so walking
/// beats slide her across while the rest swap pose.
struct Beat {
  let dog: String
  var x: CGFloat = 0
  var facing: CGFloat = 1
  var woof = false
  let seconds: Double
}

private enum Routine {
  static let beats: [Beat] = [
    Beat(dog: "idle", seconds: 20),
    Beat(dog: "scratch_1", seconds: 4),
    Beat(dog: "scratch_2", seconds: 4),
    Beat(dog: "pant_1", seconds: 5),
    Beat(dog: "pant_2", seconds: 5),
    Beat(dog: "blink", seconds: 4),
    Beat(dog: "woof", woof: true, seconds: 10),
    Beat(dog: "look", seconds: 6),
    Beat(dog: "walk_2", x: 1, seconds: 3),
    Beat(dog: "reach", x: 1, seconds: 4),
    Beat(dog: "tap", x: 1, seconds: 6),
    Beat(dog: "happy", x: 1, seconds: 12),
    Beat(dog: "walk_4", x: 0, facing: -1, seconds: 3),
    Beat(dog: "tail", seconds: 8),
    Beat(dog: "tail_down", seconds: 8),
    Beat(dog: "rest", seconds: 20),
  ]

  static let woofBeat = beats.firstIndex { $0.woof }!
  static let happyBeat = beats.firstIndex { $0.dog == "happy" }!
}

// MARK: - Timeline

struct PetEntry: TimelineEntry {
  let date: Date
  let beat: Beat
  let greeting: String
}

/// Lively for the first few minutes after each reload, then calmer (each
/// beat held longer) so an hour of routine fits one timeline and the widget
/// stays well inside WidgetKit's refresh budget.
struct PetProvider: TimelineProvider {
  private static let defaultGreeting = "Come play with me!"
  private static let livelySeconds: Double = 10 * 60
  private static let timelineSeconds: Double = 60 * 60
  private static let calmStretch: Double = 6

  func placeholder(in context: Context) -> PetEntry {
    PetEntry(date: Date(), beat: Routine.beats[0], greeting: Self.defaultGreeting)
  }

  func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
    let payload = PetPayload.load()
    let start = context.isPreview ? 0 : Self.startBeat(payload)
    completion(PetEntry(date: Date(), beat: Routine.beats[start],
                        greeting: payload.lastInteraction ?? Self.defaultGreeting))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
    let payload = PetPayload.load()
    let greeting = payload.lastInteraction ?? Self.defaultGreeting
    let now = Date()
    var entries: [PetEntry] = []
    var index = Self.startBeat(payload)
    var t: Double = 0
    while t < Self.timelineSeconds {
      let beat = Routine.beats[index]
      entries.append(PetEntry(date: now.addingTimeInterval(t), beat: beat, greeting: greeting))
      t += beat.seconds * (t < Self.livelySeconds ? 1 : Self.calmStretch)
      index = (index + 1) % Routine.beats.count
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  /// Woof right away after a tap on the puppy, look happy after playing in
  /// the app, otherwise start from the top.
  private static func startBeat(_ payload: PetPayload) -> Int {
    if let tapped = payload.woofRequestedAt, Date().timeIntervalSince(tapped) < 30 { return Routine.woofBeat }
    return payload.pose == "happy" ? Routine.happyBeat : 0
  }
}

// MARK: - Tap to woof (iOS 17+)

@available(iOSApplicationExtension 17.0, *)
struct WoofIntent: AppIntent {
  static var title: LocalizedStringResource = "Say hi to Buddy"
  static var description = IntentDescription("Makes the puppy on your Home Screen woof.")

  func perform() async throws -> some IntentResult {
    // WidgetKit reloads the timeline after the intent; the provider sees
    // this and starts on the woof beat.
    UserDefaults(suiteName: PetPayload.appGroup)?.set(Date(), forKey: PetPayload.woofKey)
    return .result()
  }
}

// MARK: - Views

/// The puppy's little stage: her ball at the right, the puppy placed
/// along the floor, and her "Woof!" bubble. Sizes are shares of the width,
/// matching the Android layout.
private struct PuppyStage: View {
  let beat: Beat

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      ZStack(alignment: .bottomLeading) {
        Image("widget_toy_ball")
          .resizable().interpolation(.high).scaledToFit()
          .frame(width: w * 0.14)
          .padding(.bottom, 4)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        Image("widget_dog_\(beat.dog)")
          .resizable().interpolation(.high).scaledToFit()
          .frame(width: w * 0.62)
          .scaleEffect(x: beat.facing, y: 1)
          .offset(x: w * 0.24 * beat.x)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
          .animation(.easeInOut(duration: 1.8), value: beat.x)
        if beat.woof {
          Image("widget_woof")
            .resizable().interpolation(.high).scaledToFit()
            .frame(width: w * 0.37)
            .offset(x: w * (0.62 + 0.24 * beat.x))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .transition(.scale(scale: 0.3, anchor: .bottomLeading).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.45, dampingFraction: 0.6), value: beat.woof)
    }
    .accessibilityHidden(true)
  }
}

/// The stage, which on iOS 17+ is also a button: tap the puppy and she
/// woofs. The rest of the widget still opens the game.
private struct Puppy: View {
  let beat: Beat

  var body: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Button(intent: WoofIntent()) { PuppyStage(beat: beat) }
        .buttonStyle(.plain)
        .accessibilityLabel("Make Buddy woof")
    } else {
      PuppyStage(beat: beat)
    }
  }
}

private struct Title: View {
  let size: CGFloat

  var body: some View {
    Text("My Pet Dog")
      .font(.system(size: size, weight: .heavy, design: .rounded))
      .foregroundColor(Pen.ink)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }
}

private struct TapPill: View {
  let size: CGFloat

  var body: some View {
    Text("Tap to Play")
      .font(.system(size: size, weight: .heavy, design: .rounded))
      .foregroundColor(Pen.ink)
      .lineLimit(1)
      .padding(.horizontal, size)
      .padding(.vertical, size * 0.3)
      .background(Capsule().fill(Pen.coralLight))
      .overlay(Capsule().stroke(Pen.ink, lineWidth: 1.5))
  }
}

private struct Greeting: View {
  let text: String
  let size: CGFloat
  let lines: Int

  var body: some View {
    Text(text)
      .font(.system(size: size, weight: .medium, design: .rounded).italic())
      .foregroundColor(Pen.pencil)
      .multilineTextAlignment(.center)
      .lineLimit(lines)
      .minimumScaleFactor(0.8)
  }
}

struct PetWidgetView: View {
  let entry: PetEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(family == .systemSmall ? 8 : 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(ContainerRelativeShape().inset(by: 3).strokeBorder(Pen.ink, lineWidth: 2.5))
      .widgetPaperBackground()
      .widgetURL(launchURL)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("My Pet Dog. \(entry.greeting) Tap to play.")
      .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .systemMedium:
      HStack(spacing: 6) {
        Puppy(beat: entry.beat).frame(maxWidth: .infinity)
        VStack(spacing: 5) {
          Title(size: 17)
          Greeting(text: entry.greeting, size: 13, lines: 2)
          Image("widget_food_bowl").resizable().scaledToFit().frame(height: 28).accessibilityHidden(true)
          TapPill(size: 12)
        }
        .frame(maxWidth: .infinity)
      }
    case .systemLarge:
      VStack(spacing: 6) {
        Title(size: 21)
        Greeting(text: entry.greeting, size: 14, lines: 1)
        ZStack(alignment: .bottom) {
          Image("widget_rug").resizable().scaledToFit().padding(.horizontal, 6).accessibilityHidden(true)
          Puppy(beat: entry.beat).padding(.horizontal, 12).padding(.bottom, 12)
          HStack {
            Image("widget_food_bowl").resizable().scaledToFit().frame(width: 56).accessibilityHidden(true)
            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        Text("Ready to play")
          .font(.system(size: 12, weight: .semibold, design: .rounded))
          .foregroundColor(Pen.inkSoft)
        TapPill(size: 14)
      }
    default:
      VStack(spacing: 2) {
        Title(size: 13)
        Puppy(beat: entry.beat).frame(maxHeight: .infinity)
        Text("Tap to play ▸")
          .font(.system(size: 10, weight: .semibold, design: .rounded))
          .foregroundColor(Pen.inkSoft)
          .lineLimit(1)
      }
    }
  }
}

private struct PaperBackground: View {
  var body: some View {
    ZStack {
      Pen.paper
      Image("widget_paper").resizable().scaledToFill()
    }
  }
}

extension View {
  /// iOS 17 requires widgets to declare their background this way.
  @ViewBuilder func widgetPaperBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { PaperBackground() }
    } else {
      background(PaperBackground())
    }
  }
}

// MARK: - Widget

struct PetWidget: Widget {
  let kind = "PetWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PetProvider()) { entry in
      PetWidgetView(entry: entry)
    }
    .configurationDisplayName("My Pet Dog")
    .description("Your puppy on your Home Screen. Tap to play.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .paperContentMargins()
  }
}

extension WidgetConfiguration {
  /// Our layout draws its own notebook margins.
  func paperContentMargins() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return contentMarginsDisabled()
    }
    return self
  }
}

@main
struct PetWidgetBundle: WidgetBundle {
  var body: some Widget {
    PetWidget()
  }
}
