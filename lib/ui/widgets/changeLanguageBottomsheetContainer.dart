import 'package:eschool/cubits/appLocalizationCubit.dart';
import 'package:eschool/data/models/appLanguage.dart';
import 'package:eschool/ui/widgets/languageFlagImage.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangeLanguageBottomsheetContainer extends StatelessWidget {
  const ChangeLanguageBottomsheetContainer({Key? key}) : super(key: key);

  Widget _buildAppLanguageTile({
    required AppLanguage appLanguage,
    required BuildContext context,
    required String currentSelectedLanguageCode,
    required bool languageChangeInProgress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        // Make the whole row tappable, not only the radio and the text.
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (languageChangeInProgress) {
            return;
          }
          context
              .read<AppLocalizationCubit>()
              .changeLanguage(appLanguage.languageCode);
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.75,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appLanguage.languageCode == currentSelectedLanguageCode
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            LanguageFlagImage(imageUrl: appLanguage.imageUrl, size: 24),
            const SizedBox(
              width: 12,
            ),
            Text(
              appLanguage.languageName,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.075),
        vertical: MediaQuery.of(context).size.height * (0.05),
      ),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(appLanguageKey),
            style: TextStyle(
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          BlocBuilder<AppLocalizationCubit, AppLocalizationState>(
            builder: (context, state) {
              final currentLanguageCode =
                  context.read<AppLocalizationCubit>().currentLanguageCode;
              return Column(
                children: [
                  ...state.availableLanguages.map(
                    (appLanguage) => _buildAppLanguageTile(
                      appLanguage: appLanguage,
                      context: context,
                      currentSelectedLanguageCode: currentLanguageCode,
                      languageChangeInProgress: state.languageChangeInProgress,
                    ),
                  ),
                  if (state.languageChangeInProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
