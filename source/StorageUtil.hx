package;

#if sys
import sys.*;
import sys.io.*;
#end
#if android
import android.content.Context;
import android.os.Environment;
import android.Permissions;
import android.Settings;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
#end
import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;

using StringTools;

@:structInit class SaveVariables {
  #if android
	public var storageType:String = "EXTERNAL_DATA";
	#end
}

class ClientPrefs {
  public static var data:SaveVariables = {};
}

class StorageUtil
{
	#if sys
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = '';
		#if android
		if (!FileSystem.exists(rootDir + 'storagetype.txt'))
			File.saveContent(rootDir + 'storagetype.txt', ClientPrefs.data.storageType);
		var curStorageType:String = File.getContent(rootDir + 'storagetype.txt');
		daPath = force ? StorageType.fromStrForce(curStorageType) : StorageType.fromStr(curStorageType);
		daPath = Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#end

		return daPath;
	}

	public static function createDirectories(directory:String):Void
	{
		try
		{
			if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
				return;
		}
		catch (e:Exception)
		{
			trace('Something went wrong while looking at directory. (${e.message})');
		}

		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:Exception)
					trace('Error while creating directory. (${e.message}');
			}
		}
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/$fileName', fileData);
			if (alert)
				CoolUtil.showPopUp('$fileName has been saved.', "Success!");
		}
		catch (e:Exception)
			if (alert)
				CoolUtil.showPopUp('$fileName couldn\'t be saved.\n(${e.message})', "Error!")
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function requestPermissions():Void
	{
		if (VERSION.SDK_INT >= VERSION_CODES.TIRAMISU)
			Permissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']);
		else
			Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!Environment.isExternalStorageManager())
		{
			if (VERSION.SDK_INT >= VERSION_CODES.S)
				Settings.requestSetting('REQUEST_MANAGE_MEDIA');
			Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}

		if ((VERSION.SDK_INT >= VERSION_CODES.TIRAMISU
			&& !Permissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (VERSION.SDK_INT < VERSION_CODES.TIRAMISU
				&& !Permissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
			CoolUtil.showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress OK to see what happens',
				'Notice!');

		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory()))
				createDirectories(StorageUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Please create directory to\n' + StorageUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
			LimeSystem.exit(1);
		}
	}

	public static function checkExternalPaths(?splitStorage = false):Array<String>
	{
		var process = new Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage)
			paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				daPath = path;

		daPath = Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
	final forcedPath = '/storage/emulated/0/';
	final packageNameLocal = 'com.ninjamuffin99.funkin';
	final fileLocal = 'Kade Engine';

	var EXTERNAL_DATA = "EXTERNAL_DATA";
	var EXTERNAL_OBB = "EXTERNAL_OBB";
	var EXTERNAL_MEDIA = "EXTERNAL_MEDIA";
	var EXTERNAL = "EXTERNAL";

	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_DATA = Context.getExternalFilesDir();
		final EXTERNAL_OBB = Context.getObbDir();
		final EXTERNAL_MEDIA = Environment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
		final EXTERNAL = Environment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final EXTERNAL_DATA = forcedPath + 'Android/data/' + packageNameLocal + '/files';
		final EXTERNAL_OBB = forcedPath + 'Android/obb/' + packageNameLocal;
		final EXTERNAL_MEDIA = forcedPath + 'Android/media/' + packageNameLocal;
		final EXTERNAL = forcedPath + '.' + fileLocal;

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}
}
#end
