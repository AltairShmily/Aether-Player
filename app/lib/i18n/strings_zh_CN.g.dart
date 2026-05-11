///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZhCn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAppZhCn app = TranslationsAppZhCn.internal(_root);
	late final TranslationsCommonZhCn common = TranslationsCommonZhCn.internal(_root);
	late final TranslationsServerSelectionZhCn serverSelection = TranslationsServerSelectionZhCn.internal(_root);
	late final TranslationsLoginZhCn login = TranslationsLoginZhCn.internal(_root);
	late final TranslationsHomeZhCn home = TranslationsHomeZhCn.internal(_root);
	late final TranslationsLibraryZhCn library = TranslationsLibraryZhCn.internal(_root);
	late final TranslationsSettingsZhCn settings = TranslationsSettingsZhCn.internal(_root);
}

// Path: app
class TranslationsAppZhCn {
	TranslationsAppZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: 'Aether'
	String get name => 'Aether';
}

// Path: common
class TranslationsCommonZhCn {
	TranslationsCommonZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '连接'
	String get connect => '连接';

	/// zh-CN: '保存'
	String get save => '保存';

	/// zh-CN: '取消'
	String get cancel => '取消';

	/// zh-CN: '删除'
	String get delete => '删除';

	/// zh-CN: '确认'
	String get confirm => '确认';

	/// zh-CN: '加载中...'
	String get loading => '加载中...';

	/// zh-CN: '错误'
	String get error => '错误';

	/// zh-CN: '成功'
	String get success => '成功';

	/// zh-CN: '重试'
	String get retry => '重试';
}

// Path: serverSelection
class TranslationsServerSelectionZhCn {
	TranslationsServerSelectionZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '选择服务器'
	String get title => '选择服务器';

	/// zh-CN: '选择一个已保存的服务器或添加新服务器'
	String get subtitle => '选择一个已保存的服务器或添加新服务器';

	/// zh-CN: '添加新服务器'
	String get addNew => '添加新服务器';

	/// zh-CN: '上次登录'
	String get lastLogin => '上次登录';

	/// zh-CN: '删除服务器'
	String get deleteServer => '删除服务器';

	/// zh-CN: '确定要删除服务器 @$serverName 吗？'
	String deleteConfirm({required Object serverName}) => '确定要删除服务器 @${serverName} 吗？';
}

// Path: login
class TranslationsLoginZhCn {
	TranslationsLoginZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '连接服务器'
	String get title => '连接服务器';

	/// zh-CN: '服务器地址'
	String get serverUrl => '服务器地址';

	/// zh-CN: 'http://your-server:8096'
	String get serverUrlHint => 'http://your-server:8096';

	/// zh-CN: '用户名'
	String get username => '用户名';

	/// zh-CN: '密码'
	String get password => '密码';

	/// zh-CN: '登录'
	String get signIn => '登录';

	/// zh-CN: '请先连接服务器'
	String get connectFirst => '请先连接服务器';

	/// zh-CN: '连接失败'
	String get connectionFailed => '连接失败';

	/// zh-CN: '登录失败'
	String get loginFailed => '登录失败';

	/// zh-CN: '登录成功'
	String get loginSuccess => '登录成功';

	/// zh-CN: '记住此服务器'
	String get rememberMe => '记住此服务器';
}

// Path: home
class TranslationsHomeZhCn {
	TranslationsHomeZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '首页'
	String get title => '首页';

	/// zh-CN: '欢迎回来, @$name'
	String welcome({required Object name}) => '欢迎回来, @${name}';

	/// zh-CN: '继续观看'
	String get continueWatching => '继续观看';

	/// zh-CN: '最近添加'
	String get recentlyAdded => '最近添加';

	/// zh-CN: '收藏'
	String get favorites => '收藏';

	/// zh-CN: '暂无内容'
	String get noItems => '暂无内容';
}

// Path: library
class TranslationsLibraryZhCn {
	TranslationsLibraryZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '媒体库'
	String get title => '媒体库';

	/// zh-CN: '电影'
	String get movies => '电影';

	/// zh-CN: '电视剧'
	String get tvShows => '电视剧';

	/// zh-CN: '音乐'
	String get music => '音乐';

	/// zh-CN: '全部'
	String get all => '全部';
}

// Path: settings
class TranslationsSettingsZhCn {
	TranslationsSettingsZhCn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '设置'
	String get title => '设置';

	/// zh-CN: '服务器'
	String get server => '服务器';

	/// zh-CN: '服务器信息'
	String get serverInfo => '服务器信息';

	/// zh-CN: '语言'
	String get language => '语言';

	/// zh-CN: '主题'
	String get theme => '主题';

	/// zh-CN: '深色模式'
	String get darkMode => '深色模式';

	/// zh-CN: '退出登录'
	String get logout => '退出登录';

	/// zh-CN: '确定要退出登录吗？'
	String get logoutConfirm => '确定要退出登录吗？';

	/// zh-CN: '中文'
	String get chinese => '中文';

	/// zh-CN: 'English'
	String get english => 'English';
}

/// The flat map containing all translations for locale <zh-CN>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Aether',
			'common.connect' => '连接',
			'common.save' => '保存',
			'common.cancel' => '取消',
			'common.delete' => '删除',
			'common.confirm' => '确认',
			'common.loading' => '加载中...',
			'common.error' => '错误',
			'common.success' => '成功',
			'common.retry' => '重试',
			'serverSelection.title' => '选择服务器',
			'serverSelection.subtitle' => '选择一个已保存的服务器或添加新服务器',
			'serverSelection.addNew' => '添加新服务器',
			'serverSelection.lastLogin' => '上次登录',
			'serverSelection.deleteServer' => '删除服务器',
			'serverSelection.deleteConfirm' => ({required Object serverName}) => '确定要删除服务器 @${serverName} 吗？',
			'login.title' => '连接服务器',
			'login.serverUrl' => '服务器地址',
			'login.serverUrlHint' => 'http://your-server:8096',
			'login.username' => '用户名',
			'login.password' => '密码',
			'login.signIn' => '登录',
			'login.connectFirst' => '请先连接服务器',
			'login.connectionFailed' => '连接失败',
			'login.loginFailed' => '登录失败',
			'login.loginSuccess' => '登录成功',
			'login.rememberMe' => '记住此服务器',
			'home.title' => '首页',
			'home.welcome' => ({required Object name}) => '欢迎回来, @${name}',
			'home.continueWatching' => '继续观看',
			'home.recentlyAdded' => '最近添加',
			'home.favorites' => '收藏',
			'home.noItems' => '暂无内容',
			'library.title' => '媒体库',
			'library.movies' => '电影',
			'library.tvShows' => '电视剧',
			'library.music' => '音乐',
			'library.all' => '全部',
			'settings.title' => '设置',
			'settings.server' => '服务器',
			'settings.serverInfo' => '服务器信息',
			'settings.language' => '语言',
			'settings.theme' => '主题',
			'settings.darkMode' => '深色模式',
			'settings.logout' => '退出登录',
			'settings.logoutConfirm' => '确定要退出登录吗？',
			'settings.chinese' => '中文',
			'settings.english' => 'English',
			_ => null,
		};
	}
}
