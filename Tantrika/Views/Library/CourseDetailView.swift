import SwiftUI

struct CourseDetailView: View {

    let course: Course
    let isSubscribed: Bool

    @State private var viewModel: CourseDetailViewModel
    @State private var selectedLesson: Lesson? = nil

    init(course: Course, isSubscribed: Bool) {
        self.course = course
        self.isSubscribed = isSubscribed
        _viewModel = State(initialValue: CourseDetailViewModel(course: course))
    }

    var body: some View {
        ZStack {
            Color.tantrikaBackground.ignoresSafeArea()

            if viewModel.isLoading && viewModel.lessons.isEmpty {
                ProgressView()
                    .tint(Color.tantrikaAccent)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.load() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Course header
                        courseHeader
                            .padding(.bottom, TantrikaSpacing.xl)

                        // Lesson list
                        Text("Lessons")
                            .font(.tantrikaSubhead)
                            .foregroundStyle(Color.tantrikaText)
                            .padding(.horizontal, TantrikaSpacing.lg)
                            .padding(.bottom, TantrikaSpacing.sm)

                        VStack(spacing: TantrikaSpacing.sm) {
                            ForEach(viewModel.lessons) { lesson in
                                LessonRow(
                                    lesson: lesson,
                                    isLocked: !lesson.isFreePreview && !isSubscribed,
                                    completion: viewModel.completionRatio(for: lesson)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { selectedLesson = lesson }
                            }
                        }
                        .padding(.horizontal, TantrikaSpacing.lg)
                        .padding(.bottom, TantrikaSpacing.xl)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .task { await viewModel.load() }
        .navigationDestination(item: $selectedLesson) { lesson in
            PlayerView(lesson: lesson)
        }
    }

    // MARK: — Course header

    private var courseHeader: some View {
        VStack(alignment: .leading, spacing: TantrikaSpacing.sm) {
            Text(course.title)
                .font(.tantrikaDisplay)
                .foregroundStyle(Color.tantrikaText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: TantrikaSpacing.xs) {
                Text("\(course.lessonCount) lessons")
                    .font(.tantrikaCaption)
                    .foregroundStyle(Color.tantrikaTextMuted)
                Text("·")
                    .font(.tantrikaCaption)
                    .foregroundStyle(Color.tantrikaTextMuted)
                Text(course.totalDurationFormatted)
                    .font(.tantrikaCaption)
                    .foregroundStyle(Color.tantrikaTextMuted)
            }

            Text(course.description)
                .font(.tantrikaBody)
                .foregroundStyle(Color.tantrikaTextMuted)
                .lineSpacing(15 * 0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TantrikaSpacing.lg)
        .padding(.top, TantrikaSpacing.xl)
    }
}

// MARK: — Lesson row

struct LessonRow: View {
    let lesson: Lesson
    let isLocked: Bool
    let completion: Double

    var body: some View {
        HStack(spacing: TantrikaSpacing.sm) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: TantrikaRadius.sm)
                .fill(Color.tantrikaSurface)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: isLocked ? "lock" : "play.fill")
                        .foregroundStyle(isLocked ? Color.tantrikaTextMuted : Color.tantrikaAccent)
                        .font(.system(size: 20))
                )

            // Info
            VStack(alignment: .leading, spacing: TantrikaSpacing.xxs) {
                Text(lesson.title)
                    .font(.tantrikaHeading)
                    .foregroundStyle(Color.tantrikaText)
                    .lineLimit(2)

                HStack(spacing: TantrikaSpacing.xs) {
                    Text(lesson.durationFormatted)
                        .font(.tantrikaCaption)
                        .foregroundStyle(Color.tantrikaTextMuted)

                    if lesson.isFreePreview {
                        BadgeView(label: "Free preview", style: .preview)
                    } else if isLocked {
                        BadgeView(label: "Members only", style: .members)
                    }
                }

                // Progress bar
                if completion > 0 {
                    ProgressBarView(value: completion)
                        .frame(height: 4)
                        .padding(.top, TantrikaSpacing.xxs)
                }
            }

            Spacer()
        }
        .padding(TantrikaSpacing.sm)
        .background(Color.tantrikaSurface)
        .cornerRadius(TantrikaRadius.lg)
        .shadow(color: Color.tantrikaText.opacity(0.08), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lesson.title), \(lesson.durationFormatted), \(isLocked ? "Members only" : lesson.isFreePreview ? "Free preview" : "Unlocked")")
    }
}

// MARK: — Badge view

enum BadgeStyle { case preview, members }

struct BadgeView: View {
    let label: String
    let style: BadgeStyle

    var body: some View {
        Text(label)
            .font(.tantrikaCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, TantrikaSpacing.xs)
            .padding(.vertical, TantrikaSpacing.xxs)
            .background(style == .preview ? Color.tantrikaSage : Color.tantrikaAccent)
            .clipShape(Capsule())
    }
}

// MARK: — Progress bar

struct ProgressBarView: View {
    let value: Double // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: TantrikaRadius.full)
                    .fill(Color.tantrikaSurface)
                RoundedRectangle(cornerRadius: TantrikaRadius.full)
                    .fill(Color.tantrikaAccent)
                    .frame(width: geo.size.width * value)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: Course.mockData[0], isSubscribed: false)
    }
}
