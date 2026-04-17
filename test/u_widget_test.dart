import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

void main() {
  group('UThemeData', () {
    test('defaultTheme should have teal primary color', () {
      final theme = UThemeData.defaultTheme();
      expect(theme.primary, equals(const Color(0xFF009688)));
    });

    test('defaultTheme should have correct border radius values', () {
      final theme = UThemeData.defaultTheme();
      expect(theme.borderRadiusSmall, equals(4.0));
      expect(theme.borderRadiusMedium, equals(8.0));
      expect(theme.borderRadiusLarge, equals(12.0));
    });

    test('defaultTheme should have correct spacing values', () {
      final theme = UThemeData.defaultTheme();
      expect(theme.spacingTiny, equals(4.0));
      expect(theme.spacingSmall, equals(8.0));
      expect(theme.spacingMedium, equals(16.0));
      expect(theme.spacingLarge, equals(24.0));
      expect(theme.spacingXLarge, equals(32.0));
    });

    test('shadcn should have black primary color', () {
      final theme = UThemeData.shadcn();
      expect(theme.primary, equals(const Color(0xFF000000)));
    });

    test('toMaterial should return valid ThemeData', () {
      final theme = UThemeData.defaultTheme();
      final materialTheme = theme.toMaterial();
      expect(materialTheme, isA<ThemeData>());
      expect(materialTheme.primaryColor, equals(theme.primary));
    });
  });

  group('UTheme', () {
    testWidgets('should distribute theme data to descendants', (tester) async {
      final theme = UThemeData.defaultTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: theme,
            child: Builder(
              builder: (context) {
                final inheritedTheme = UTheme.of(context);
                return Text('Primary: ${inheritedTheme.primary}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Primary: ${theme.primary}'), findsOneWidget);
    });

    testWidgets('should return default theme when no UTheme ancestor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final theme = UTheme.of(context);
              return Text('Primary: ${theme.primary}');
            },
          ),
        ),
      );

      final defaultTheme = UThemeData.defaultTheme();
      expect(find.text('Primary: ${defaultTheme.primary}'), findsOneWidget);
    });
  });

  group('UButton', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: const Scaffold(body: UButton(child: Text('Button'))),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UButton(
                onPressed: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UButton(
                onLongPressed: () => longPressed = true,
                child: const Text('Long Press Me'),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Long Press Me'));
      expect(longPressed, isTrue);
    });

    testWidgets('renders different button types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: Wrap(
                children: [
                  UButton(child: const Text('Text')),
                  UButton(child: const Text('Filled')),
                  UButton(child: const Text('Outlined')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Filled'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('disabled button does not respond to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UButton(
                enabled: false,
                onPressed: () => tapped = true,
                child: const Text('Disabled Button'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled Button'));
      expect(tapped, isFalse);
    });
  });

  group('UInput', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: const Scaffold(body: UInput(hintText: 'Enter text')),
          ),
        ),
      );

      expect(find.text('Enter text'), findsOneWidget);
    });

    testWidgets('shows password toggle for password type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: const Scaffold(body: UInput(type: UInputType.password)),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      final controller = TextEditingController(text: 'test');

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UInput(showClearIcon: true, cntlr: controller),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(controller.text, equals(''));
    });

    testWidgets('accepts only numbers for number type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: const Scaffold(body: UInput(type: UInputType.number)),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, equals(TextInputType.number));
    });

    testWidgets('shows prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: const Scaffold(
              body: UInput(
                prefix: Icon(Icons.search),
                suffix: Icon(Icons.settings),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('UScrollPicker', () {
    testWidgets('renders with items', (tester) async {
      final items = [
        UScrollPickerItem<String>(value: 'Item 1'),
        UScrollPickerItem<String>(value: 'Item 2'),
        UScrollPickerItem<String>(value: 'Item 3'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UScrollPicker<String>(items: items, onChanged: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('renders correctly without crashing', (tester) async {
      final items = [
        UScrollPickerItem<String>(value: 'Item 1'),
        UScrollPickerItem<String>(value: 'Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UScrollPicker<String>(items: items, onChanged: (values) {}),
            ),
          ),
        ),
      );

      expect(find.byType(UScrollPicker<String>), findsOneWidget);
    });
  });

  group('UFileItem', () {
    test('creates file item with all properties', () {
      final item = UFileItem(
        name: 'test.txt',
        path: '/path/to/test.txt',
        type: 'file',
        size: 1024,
        modified: DateTime(2024, 1, 1),
      );

      expect(item.name, equals('test.txt'));
      expect(item.path, equals('/path/to/test.txt'));
      expect(item.type, equals('file'));
      expect(item.size, equals(1024));
      expect(item.modified, equals(DateTime(2024, 1, 1)));
    });
  });

  group('UFileListWidget', () {
    testWidgets('renders file items', (tester) async {
      final files = [
        UFileItem(
          name: 'test.txt',
          path: '/test.txt',
          type: 'file',
          modified: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UFileListWidget(
                files: files,
                onItemTap: (_) {},
                onShowMenu: (_, __) {},
                onItemDoubleTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('test.txt'), findsOneWidget);
    });

    testWidgets('shows icons when enabled', (tester) async {
      final files = [
        UFileItem(
          name: 'test.txt',
          path: '/test.txt',
          type: 'file',
          modified: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UFileListWidget(
                files: files,
                showIcons: true,
                onItemTap: (_) {},
                onShowMenu: (_, __) {},
                onItemDoubleTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
    });

    testWidgets('renders correctly without crashing', (tester) async {
      final files = [
        UFileItem(
          name: 'test.txt',
          path: '/test.txt',
          type: 'file',
          modified: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UFileListWidget(
                files: files,
                onItemTap: (_) {},
                onShowMenu: (_, __) {},
                onItemDoubleTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UFileListWidget), findsOneWidget);
    });
  });

  group('UNavigationBar', () {
    testWidgets('renders navigation buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UNavigationBar(
                currentPath: '/test',
                onHome: () {},
                onBack: () {},
                onForward: () {},
                onUp: () {},
                onRefresh: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: UNavigationBar(
                currentPath: '/test',
                onHome: () {},
                onBack: () {},
                onForward: () {},
                onUp: () {},
                onRefresh: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UNavigationBar), findsOneWidget);
    });
  });

  group('UTreeNode', () {
    test('creates tree node with data', () {
      final node = UTreeNode<String>(data: 'Test Node');
      expect(node.data, equals('Test Node'));
    });

    test('creates tree node with children', () {
      final child = UTreeNode<String>(data: 'Child');
      final parent = UTreeNode<String>(data: 'Parent', children: [child]);
      expect(parent.children.length, equals(1));
      expect(parent.children.first.data, equals('Child'));
    });

    test('generates correct path', () {
      final root = UTreeNode<String>(data: 'Root');
      final child = UTreeNode<String>(data: 'Child', parent: root);
      expect(child.path.segments, isEmpty);
    });
  });

  group('USplitPanel', () {
    test('creates panel with child and flex', () {
      final panel = USplitPanel(child: Text('Test'), flex: 2);
      expect(panel.flex, equals(2));
    });

    test('creates panel with default flex of 1', () {
      final panel = USplitPanel(child: Text('Test'));
      expect(panel.flex, equals(1));
    });
  });

  group('USplitLayout', () {
    testWidgets('renders panels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UTheme(
            data: UThemeData.defaultTheme(),
            child: Scaffold(
              body: USplitLayout(
                direction: Axis.horizontal,
                panels: [
                  USplitPanel(child: Container(color: Colors.red), flex: 1),
                  USplitPanel(child: Container(color: Colors.blue), flex: 1),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(USplitLayout), findsOneWidget);
    });
  });

  group('UNavCntlr', () {
    test('initial state', () {
      final controller = UNavCntlr();
      expect(controller.curPath, equals('/'));
      expect(controller.canPop(), isFalse);
      expect(controller.canForward(), isFalse);
    });

    test('canUp returns true for paths starting with separator', () {
      final controller = UNavCntlr();
      controller.curPath = '/Users/Documents';
      expect(controller.canUp(), isTrue);
    });
  });
}
