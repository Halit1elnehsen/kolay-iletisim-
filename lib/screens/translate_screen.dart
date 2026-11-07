import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
import 'offline_phrases_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    provider.bind(
      context.read<HistoryProvider>(),
      context.watch<SettingsProvider>(),
    );
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 740;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 20,
                24,
                wide ? 40 : 20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!wide)
                            const Icon(
                              Icons.forum_rounded,
                              color: AppColors.accentCyan,
                              size: 26,
                            ),
                          if (!wide) const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Kolay İletişim',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Çeviri geçmişi',
                            onPressed: () =>
                                _open(context, const HistoryScreen()),
                            icon: const Icon(
                              Icons.history_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ayarlar',
                            onPressed: () =>
                                _open(context, const SettingsScreen()),
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? 48 : 32),
                      Text(
                        'Kelimelerin ötesinde,',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: wide ? 42 : 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'birbirimizi anlayalım.',
                        style: TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: wide ? 42 : 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Yaz, konuş veya kameranla çevir. İletişime yer aç.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarker,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _language(context, provider, true)),
                            IconButton(
                              tooltip: 'Dillerin yerini değiştir',
                              onPressed: provider.isProcessing
                                  ? null
                                  : provider.swapLanguages,
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                color: AppColors.accentCyan,
                              ),
                            ),
                            Expanded(
                              child: _language(context, provider, false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (wide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _input(provider)),
                              const SizedBox(width: 16),
                              Expanded(child: _output(context, provider)),
                            ],
                          ),
                        )
                      else ...[
                        _input(provider),
                        const SizedBox(height: 16),
                        _output(context, provider),
                      ],
                      if (provider.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              provider.error,
                              style: const TextStyle(
                                color: AppColors.accentRose,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                provider.isProcessing || provider.isListening
                                ? null
                                : provider.translateText,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              foregroundColor: AppColors.bgDeep,
                              minimumSize: const Size(150, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: provider.isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.bgDeep,
                                    ),
                                  )
                                : const Icon(Icons.translate_rounded, size: 20),
                            label: Text(
                              provider.isProcessing
                                  ? 'Çevriliyor…'
                                  : 'Metni çevir',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: provider.isProcessing
                                ? null
                                : () => provider.isListening
                                      ? provider.stopListening()
                                      : provider.startListening(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: provider.isListening
                                  ? AppColors.accentRose
                                  : AppColors.textPrimary,
                              minimumSize: const Size(150, 52),
                              side: const BorderSide(
                                color: AppColors.borderHover,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: Icon(
                              provider.isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_none_rounded,
                            ),
                            label: Text(
                              provider.isListening
                                  ? 'Dinlemeyi bitir'
                                  : 'Konuşarak çevir',
                            ),
                          ),
                          if (provider.isListening)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                'Dinleniyor…',
                                style: TextStyle(color: AppColors.accentCyan),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: () =>
                            _open(context, const OfflinePhrasesScreen()),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_outlined,
                                  color: AppColors.accentGold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Her yolculukta işine yarar',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'İnternetsiz kullanabileceğin hazır cümleler',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _language(
    BuildContext context,
    TranslationProvider provider,
    bool source,
  ) {
    final lang = source ? provider.source : provider.target;
    return TextButton(
      onPressed: provider.isProcessing
          ? null
          : () => _pickLanguage(context, provider, source),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source ? 'Kaynak dil' : 'Çeviri dili',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, bool highlighted = false}) => Container(
    constraints: const BoxConstraints(minHeight: 244),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFF162F36) : AppColors.bgCard,
      border: Border.all(
        color: highlighted ? const Color(0xFF325D61) : AppColors.border,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );

  Widget _input(TranslationProvider provider) => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Senin cümlelerin',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Metni temizle',
              onPressed: provider.reset,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: provider.textController,
          minLines: 4,
          maxLines: 8,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            height: 1.6,
          ),
          textDirection: provider.source == AppLanguage.arabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'Ne söylemek istersin?',
            filled: false,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 20),
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ],
    ),
  );

  Widget _output(BuildContext context, TranslationProvider provider) => _panel(
    highlighted: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Çevirin',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Çeviriyi dinle',
              onPressed: provider.hasTranslation && !provider.isSpeaking
                  ? provider.speakTranslation
                  : null,
              icon: Icon(
                Icons.volume_up_outlined,
                size: 20,
                color: provider.hasTranslation
                    ? AppColors.accentCyan
                    : AppColors.textMuted,
              ),
            ),
            IconButton(
              tooltip: 'Çeviriyi kopyala',
              onPressed: !provider.hasTranslation
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: provider.state.translatedText),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Çeviri kopyalandı.')),
                        );
                      }
                    },
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: provider.hasTranslation
                    ? AppColors.accentCyan
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: SelectableText(
            provider.hasTranslation
                ? provider.state.translatedText
                : 'Yeni bir dilde, aynı sen.',
            textDirection:
                provider.hasTranslation && provider.target == AppLanguage.arabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: TextStyle(
              color: provider.hasTranslation
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontSize: 20,
              height: 1.6,
            ),
          ),
        ),
        if (!provider.hasTranslation)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Çevirin burada görünecek.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
      ],
    ),
  );

  void _pickLanguage(
    BuildContext context,
    TranslationProvider provider,
    bool source,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgDeep,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                source ? 'Kaynak dili seç' : 'Çeviri dilini seç',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final lang in AppLanguage.values)
              ListTile(
                textColor: AppColors.textPrimary,
                title: Text(lang.label),
                trailing: (source ? provider.source : provider.target) == lang
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.accentCyan,
                      )
                    : null,
                onTap: () {
                  source ? provider.setSource(lang) : provider.setTarget(lang);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
