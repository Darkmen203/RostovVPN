// nav_bar.dart
import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';

/// Компонент (виджет) NavBar.
/// Он принимает снаружи:
/// 1) [selectedIndex] — индекс текущей вкладки,
/// 2) [onTabSelected] — колбэк, который вызывается при переключении вкладок.
class NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const NavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        border: BorderDirectional(
          top: BorderSide(
            // color: Colors.black,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTabSelected,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.pink,
            unselectedItemColor: Colors.white,
            iconSize: 40,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline_rounded),
                label: 'About',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
