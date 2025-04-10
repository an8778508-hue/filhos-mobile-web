import 'package:escola/core/components/fader.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class TextHtml extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double? maxHeight;

  const TextHtml(
    this.text, {
    this.style,
    this.textAlign,
    this.maxHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = HtmlWidget(
      text,
      textStyle: style,
      onTapImage: (meta) {
        final sources = meta.sources;
        bool find(ImageSource src) => validString(src.url);
        if (sources.any(find)) {
          final src = sources.firstWhere(find).url;
          Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewer(url: src, tag: src)));
        }
      },
      onLoadingBuilder: (context, element, loadingProgress) => const Center(child: Loading()),
      renderMode: RenderMode.column,
      factoryBuilder: () => CustomHTMLFactory(
        textAlign: textAlign,
      ),
    );

    // if (maxHeight != null) {
    //   return Fader(
    //     height: maxHeight,
    //     child: child,
    //   );
    // }

    return child;
  }
}

class CustomHTMLFactory extends WidgetFactory {
  final TextAlign? textAlign;

  CustomHTMLFactory({
    this.textAlign,
  });

  @override
  Widget buildText(BuildMetadata meta, TextStyleHtml tsh, InlineSpan text) {
    final def = super.buildText(meta, tsh, text) ?? const SizedBox();
    if (text is! TextSpan) {
      return def;
    }
    return SelectableText.rich(
      text,
      style: tsh.style,
      textAlign: textAlign ?? tsh.textAlign,
      textDirection: tsh.textDirection,
    );
  }
}
