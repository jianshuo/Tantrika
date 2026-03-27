import SwiftUI

struct LibraryView: View {

    @State private var viewModel = LibraryViewModel()
    @State private var selectedCourse: Course? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tantrikaBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.courses.isEmpty {
                    ProgressView()
                        .tint(Color.tantrikaAccent)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.load() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            teacherHeroSection
                                .padding(.bottom, TantrikaSpacing.xl)

                            coursesSection
                        }
                        .padding(.bottom, TantrikaSpacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task { await viewModel.load() }
        .navigationDestination(item: $selectedCourse) { course in
            CourseDetailView(course: course, isSubscribed: viewModel.isSubscribed)
        }
    }

    // MARK: — Teacher hero

    private var teacherHeroSection: some View {
        HStack(spacing: TantrikaSpacing.sm) {
            Circle()
                .fill(Color.tantrikaSurface)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(Color.tantrikaAccent, lineWidth: 2)
                )
                .accessibilityLabel("Astiko")

            VStack(alignment: .leading, spacing: TantrikaSpacing.xxs) {
                Text("Astiko")
                    .font(.tantrikaSubhead)
                    .foregroundStyle(Color.tantrikaText)

                Text("Welcome to the practice.")
                    .font(.tantrikaHeadingItalic)
                    .foregroundStyle(Color.tantrikaTextMuted)
            }

            Spacer()
        }
        .padding(.horizontal, TantrikaSpacing.lg)
        .padding(.top, TantrikaSpacing.xl)
    }

    // MARK: — Course list

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: TantrikaSpacing.xl) {
            Text("Courses")
                .font(.tantrikaSubhead)
                .foregroundStyle(Color.tantrikaText)
                .padding(.horizontal, TantrikaSpacing.lg)

            VStack(spacing: TantrikaSpacing.sm) {
                ForEach(viewModel.courses) { course in
                    CourseCard(course: course)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCourse = course }
                }
            }
            .padding(.horizontal, TantrikaSpacing.lg)
        }
    }
}

// MARK: — Course card

private struct CourseCard: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: TantrikaSpacing.xs) {
            Text(course.title)
                .font(.tantrikaHeading)
                .foregroundStyle(Color.tantrikaText)
                .lineLimit(2)

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
                .lineLimit(3)
                .padding(.top, TantrikaSpacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TantrikaSpacing.md)
        .background(Color.tantrikaSurface)
        .cornerRadius(TantrikaRadius.lg)
        .shadow(color: Color.tantrikaText.opacity(0.08), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Course: \(course.title), \(course.lessonCount) lessons")
    }
}

// MARK: — Shared error view

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: TantrikaSpacing.md) {
            Text(message)
                .font(.tantrikaBody)
                .foregroundStyle(Color.tantrikaTextMuted)
                .multilineTextAlignment(.center)

            Button("Try again", action: retry)
                .font(.tantrikaButton)
                .foregroundStyle(Color.tantrikaAccent)
        }
        .padding(TantrikaSpacing.lg)
    }
}

#Preview {
    LibraryView()
}
