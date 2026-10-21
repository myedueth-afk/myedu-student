import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/childTeachersCubit.dart';
import 'package:eschool/data/models/subjectTeacher.dart';
import 'package:eschool/data/repositories/parentRepository.dart';
import 'package:eschool/ui/widgets/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// A group of [SubjectTeacher] entries that share the same teacher.
class _TeacherGroup {
  final SubjectTeacher representative;
  final List<SubjectTeacher> entries;

  _TeacherGroup({required this.representative, required this.entries});

  int get teacherId => representative.teacherId ?? -1;
  List<String> get subjectNames =>
      entries.map((e) => e.subject?.nameWithType ?? '').toList();
}

class ChildTeachersScreen extends StatefulWidget {
  final int childId;
  const ChildTeachersScreen({Key? key, required this.childId})
      : super(key: key);

  @override
  State<ChildTeachersScreen> createState() => _ChildTeachersScreenState();

  static Widget routeInstance() {
    return BlocProvider<ChildTeachersCubit>(
      create: (context) => ChildTeachersCubit(ParentRepository()),
      child: ChildTeachersScreen(childId: Get.arguments as int),
    );
  }
}

class _ChildTeachersScreenState extends State<ChildTeachersScreen> {
  // ── helpers ──────────────────────────────────────────────────────────────

  /// Groups a flat list of [SubjectTeacher] records by teacher id.
  List<_TeacherGroup> _groupByTeacher(List<SubjectTeacher> items) {
    final map = <int, List<SubjectTeacher>>{};
    for (final item in items) {
      final id = item.teacherId ?? -1;
      map.putIfAbsent(id, () => []).add(item);
    }
    return map.entries
        .map((e) =>
            _TeacherGroup(representative: e.value.first, entries: e.value))
        .toList();
  }

  // ── bottom sheet ─────────────────────────────────────────────────────────

  void _showAllSubjectsSheet(
      BuildContext context, String teacherName, List<String> subjects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectsBottomSheet(
        teacherName: teacherName,
        subjects: subjects,
      ),
    );
  }

  // ── teacher card ─────────────────────────────────────────────────────────

  static const int _maxVisibleSubjects = 2;

  Widget _buildTeacherCard(_TeacherGroup group) {
    final bool isParent = context.read<AuthCubit>().isParent();
    final teacher = group.representative.teacher;
    final subjects = group.subjectNames;
    final visibleSubjects = subjects.take(_maxVisibleSubjects).toList();
    final extraCount = subjects.length - _maxVisibleSubjects;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width * 0.90,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: const Offset(2.5, 2.5),
            blurRadius: 10,
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
          )
        ],
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomUserProfileImageWidget(
                  profileUrl: teacher?.image ?? "",
                  radius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name + subjects + phone ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Teacher name
                  Text(
                    teacher?.fullName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subject rows — no truncation, full text wraps naturally
                  ...visibleSubjects.map(
                    (s) => _SubjectRow(label: s, primary: primary),
                  ),

                  // "+ N more" button — only shown when needed
                  if (extraCount > 0) ...[
                    const SizedBox(height: 4),
                    _MoreButton(
                      count: extraCount,
                      primary: primary,
                      onTap: () => _showAllSubjectsSheet(
                        context,
                        teacher?.fullName ?? "",
                        subjects,
                      ),
                    ),
                  ],

                  // Phone (parent only)
                  if (isParent && (teacher?.mobile ?? "").isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.call_outlined,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            Utils.formatMobileNumber(
                              countryCode: teacher?.countryCode,
                              mobile: teacher?.mobile,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width * 0.90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, bc) {
          return Row(
            children: [
              ShimmerLoadingContainer(
                child: CustomShimmerContainer(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 60,
                  height: 60,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoadingContainer(
                      child: CustomShimmerContainer(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: bc.maxWidth * 0.55,
                      ),
                    ),
                    ShimmerLoadingContainer(
                      child: CustomShimmerContainer(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: bc.maxWidth * 0.70,
                        height: 22,
                        borderRadius: 20,
                      ),
                    ),
                    ShimmerLoadingContainer(
                      child: CustomShimmerContainer(
                        width: bc.maxWidth * 0.35,
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // ── main list ─────────────────────────────────────────────────────────────

  Widget _buildTeachers() {
    return BlocBuilder<ChildTeachersCubit, ChildTeachersState>(
      builder: (context, state) {
        if (state is ChildTeachersFetchSuccess) {
          final groups = _groupByTeacher(state.subjectTeachers);
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
                bottom: 20,
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: groups.isEmpty
                      ? [const NoDataContainer(titleKey: noTeachersFoundKey)]
                      : List.generate(
                          groups.length,
                          (index) => Animate(
                            effects: listItemAppearanceEffects(
                              itemIndex: index,
                              totalLoadedItems: groups.length,
                            ),
                            child: _buildTeacherCard(groups[index]),
                          ),
                        ),
                ),
              ),
            ),
          );
        }

        if (state is ChildTeachersFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context
                    .read<ChildTeachersCubit>()
                    .fetchChildTeachers(childId: widget.childId);
              },
            ),
          );
        }

        // Loading state
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
            ),
            child: Column(
              children: List.generate(
                Utils.defaultShimmerLoadingContentCount,
                (_) => _buildShimmerCard(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      context
          .read<ChildTeachersCubit>()
          .fetchChildTeachers(childId: widget.childId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildTeachers(),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: Utils.getTranslatedLabel(teachersKey),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ────────────────────────────────────────────────────────────────────────────

/// A single subject displayed as a colored dot + full-wrapping text row.
/// No truncation — the text wraps to as many lines as needed.
class _SubjectRow extends StatelessWidget {
  final String label;
  final Color primary;
  const _SubjectRow({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Solid accent pill that clearly signals it is tappable to see more.
class _MoreButton extends StatelessWidget {
  final int count;
  final Color primary;
  final VoidCallback onTap;
  const _MoreButton(
      {required this.count, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "+$count more subject${count == 1 ? '' : 's'}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: primary),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bottom sheet – all subjects list
// ────────────────────────────────────────────────────────────────────────────

class _SubjectsBottomSheet extends StatelessWidget {
  final String teacherName;
  final List<String> subjects;

  const _SubjectsBottomSheet({
    required this.teacherName,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "${subjects.length} subject${subjects.length == 1 ? '' : 's'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.grey.shade200, height: 1),

              // Subject list
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subjects[index],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
