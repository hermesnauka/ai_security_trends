package com.kotlinguard.ui.screens

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.testTag
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.kotlinguard.data.di.DataContainer
import com.kotlinguard.ui.viewmodel.ThreatDetailViewModelFactory
import com.kotlinguard.ui.viewmodel.ViewModelFactory

private sealed class Tab(val route: String, val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    data object Frameworks : Tab("frameworks", "Frameworki", Icons.Filled.GridView)
    data object Threats : Tab("threats", "Zagrożenia", Icons.Filled.Shield)
    data object Search : Tab("search", "Szukaj", Icons.Filled.Search)
    data object Bookmarks : Tab("bookmarks", "Zakładki", Icons.Filled.Bookmark)
    data object About : Tab("about", "O aplikacji", Icons.Filled.Info)
}

private val tabs = listOf(Tab.Frameworks, Tab.Threats, Tab.Search, Tab.Bookmarks, Tab.About)

/**
 * PLAN.md §8: `RootScreen` → bottom navigation: Frameworks | Threats |
 * Search | Bookmarks | About — the top-level navigation shell, the Compose
 * `NavHost` analogue of app11's SwiftUI `TabView` (`RootView.swift`) and
 * app09's WordPress Template Hierarchy routes, but native.
 */
@Composable
fun RootScreen(factory: ViewModelFactory, dataContainer: DataContainer) {
    val navController = rememberNavController()

    Scaffold(
        bottomBar = {
            NavigationBar {
                val backStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = backStackEntry?.destination
                // Stable, English, test-only tags — deliberately separate from
                // the visible Polish labels, so Compose UI tests (see
                // `app/src/androidTest/`) don't break every time a display
                // string changes or gets translated.
                tabs.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        modifier = androidx.compose.ui.Modifier.testTag("tab-${tab.route}")
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Tab.Frameworks.route,
            modifier = androidx.compose.ui.Modifier.padding(padding)
        ) {
            composable(Tab.Frameworks.route) {
                FrameworkListScreen(factory) { frameworkCode ->
                    navController.navigate("threats/$frameworkCode")
                }
            }
            composable(Tab.Threats.route) {
                ThreatBrowserScreen(factory, frameworkCode = null) { code ->
                    navController.navigate("threat/$code")
                }
            }
            composable("threats/{frameworkCode}") { backStackEntry ->
                val frameworkCode = backStackEntry.arguments?.getString("frameworkCode")
                ThreatBrowserScreen(factory, frameworkCode = frameworkCode) { code ->
                    navController.navigate("threat/$code")
                }
            }
            composable("threat/{code}") { backStackEntry ->
                val code = backStackEntry.arguments?.getString("code") ?: return@composable
                ThreatDetailScreen(ThreatDetailViewModelFactory(dataContainer, code), code)
            }
            composable(Tab.Search.route) {
                SearchScreen(factory) { code -> navController.navigate("threat/$code") }
            }
            composable(Tab.Bookmarks.route) {
                BookmarksScreen(factory) { code -> navController.navigate("threat/$code") }
            }
            composable(Tab.About.route) { AboutScreen() }
            composable("digitalharms") { DigitalHarmsScreen(factory) }
        }
    }
}
