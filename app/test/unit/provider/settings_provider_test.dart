import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:flutter/material.dart';

import 'settings_provider_test.mocks.dart';

@GenerateMocks([PersistenceService])
void main() {
  group('SettingsService Mutual Exclusivity', () {
    late MockPersistenceService persistence;
    late RefenaContainer container;

    setUp(() {
      persistence = MockPersistenceService();

      // Default mock values
      when(persistence.getShowToken()).thenReturn('');
      when(persistence.getAlias()).thenReturn('alias');
      when(persistence.getTheme()).thenReturn(ThemeMode.system);
      when(persistence.getColorMode()).thenReturn(ColorMode.system);
      when(persistence.getLocale()).thenReturn(null);
      when(persistence.getPort()).thenReturn(8080);
      when(persistence.getNetworkWhitelist()).thenReturn(null);
      when(persistence.getNetworkBlacklist()).thenReturn(null);
      when(persistence.getMulticastGroup()).thenReturn('224.0.0.1');
      when(persistence.getDestination()).thenReturn(null);
      when(persistence.isSaveToGallery()).thenReturn(false);
      when(persistence.isSaveToHistory()).thenReturn(true);
      when(persistence.isQuickSave()).thenReturn(false);
      when(persistence.isQuickSaveFromFavorites()).thenReturn(false);
      when(persistence.getReceivePin()).thenReturn(null);
      when(persistence.isAutoFinish()).thenReturn(false);
      when(persistence.isMinimizeToTray()).thenReturn(false);
      when(persistence.isHttps()).thenReturn(true);
      when(persistence.getSendMode()).thenReturn(SendMode.single);
      when(persistence.getSaveWindowPlacement()).thenReturn(true);
      when(persistence.getEnableAnimations()).thenReturn(true);
      when(persistence.getDeviceType()).thenReturn(null);
      when(persistence.getDeviceModel()).thenReturn(null);
      when(persistence.getShareViaLinkAutoAccept()).thenReturn(false);
      when(persistence.getDiscoveryTimeout()).thenReturn(30000);
      when(persistence.getAdvancedSettingsEnabled()).thenReturn(false);
      when(persistence.isAutoCopyText()).thenReturn(false);
      when(persistence.isAutoInstallApk()).thenReturn(false);

      container = RefenaContainer();
      container.set(persistenceProvider.overrideWithValue(persistence));
    });

    test('setQuickSave(true) should disable quickSaveFromFavorites', () async {
      final service = container.notifier(settingsProvider);

      await service.setQuickSave(true);

      expect(container.read(settingsProvider).quickSave, true);
      expect(container.read(settingsProvider).quickSaveFromFavorites, false);
      verify(persistence.setQuickSave(true)).called(1);
      verify(persistence.setQuickSaveFromFavorites(false)).called(1);
    });

    test('setQuickSaveFromFavorites(true) should disable quickSave', () async {
      final service = container.notifier(settingsProvider);

      await service.setQuickSaveFromFavorites(true);

      expect(container.read(settingsProvider).quickSaveFromFavorites, true);
      expect(container.read(settingsProvider).quickSave, false);
      verify(persistence.setQuickSaveFromFavorites(true)).called(1);
      verify(persistence.setQuickSave(false)).called(1);
    });
  });
}
