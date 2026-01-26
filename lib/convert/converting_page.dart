import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ConvertingPage extends StatefulWidget {
  const ConvertingPage({super.key});

  @override
  State<ConvertingPage> createState() => _ConvertingPageState();
}

class _ConvertingPageState extends State<ConvertingPage>
    with TickerProviderStateMixin {
  AnimationController? dotController;
  AnimationController? spinController;

  @override
  void initState() {
    super.initState();

    dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    dotController?.dispose();
    spinController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
        title: Text(
          "Converting",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          /// animated dots
          if (dotController != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: dotController!,
                  builder: (_, __) {
                    double scale = 1 +
                        (0.5 *
                            (1 -
                                ((dotController!.value - index * 0.3)
                                    .abs() *
                                    2)
                                    .clamp(0.0, 1.0)));
                    return Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ".",
                          style: TextStyle(
                            fontSize: 60,
                            color: index == 0
                                ? theme.colorScheme.onBackground
                                : index == 1
                                ? Colors.purple
                                : Colors.deepOrange,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

          const SizedBox(height: 50),

          /// rotating converting icon
          if (spinController != null)
            RotationTransition(
              turns: spinController!,
              child: Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(IconsaxPlusBold.blend,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 45),

          /// conversion card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.grey.shade300,
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 13),
                  Text(
                    '\$100 = 76,260.50',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRow("You will get:", "76,260.50", theme),
                  _buildRow("Rate:", "1 USD = 1,200 NGN", theme),
                  _buildRow("Service Fee:", "\$5.00", theme),
                  _buildRow("Total:", "\$105", theme),
                  const Spacer(),
                  Container(
                    height: 70,
                    width: 70,
                    decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          spreadRadius: 1,
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: const Icon(IconsaxPlusBold.arrow_circle_right,
                        size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
              )),
          Text(value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              )),
        ],
      ),
    );
  }
}
