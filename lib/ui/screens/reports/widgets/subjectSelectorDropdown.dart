import 'package:eschool/data/models/subject.dart';
import 'package:eschool/ui/widgets/customBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// Tappable dropdown container that shows the selected subject name and a
/// chevron. Tapping it opens a bottomsheet where the user can pick a
/// different subject from the [subjects] list.
class SubjectSelectorDropdown extends StatelessWidget {
  final List<Subject> subjects;
  final Subject selectedSubject;
  final ValueChanged<Subject> onChanged;

  const SubjectSelectorDropdown({
    Key? key,
    required this.subjects,
    required this.selectedSubject,
    required this.onChanged,
  }) : super(key: key);

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectPickerSheet(
        subjects: subjects,
        selectedSubject: selectedSubject,
        onChanged: (subject) {
          Navigator.of(context).pop();
          onChanged(subject);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Utils.getColorScheme(context).surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                Utils.getColorScheme(context).onSurface.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedSubject.getSubjectName(context: context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Utils.getColorScheme(context).onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Utils.getColorScheme(context)
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectPickerSheet extends StatelessWidget {
  final List<Subject> subjects;
  final Subject selectedSubject;
  final ValueChanged<Subject> onChanged;

  const _SubjectPickerSheet({
    required this.subjects,
    required this.selectedSubject,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: selectSubjectsKey,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...subjects.map((subject) {
            final isSelected =
                subject.classSubjectId == selectedSubject.classSubjectId;
            return _SubjectPickerTile(
              subject: subject,
              isSelected: isSelected,
              onTap: () => onChanged(subject),
            );
          }),
        ],
      ),
    );
  }
}

class _SubjectPickerTile extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubjectPickerTile({
    required this.subject,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subject.getSubjectName(context: context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                child: isSelected
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
