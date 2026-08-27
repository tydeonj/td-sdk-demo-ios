// 空 Swift 文件：让纯 ObjC Demo 走 Swift 链接器，解析 LitemobSDK 的 @rpath/libswiftCore.dylib。
// iOS 12.2+ 必须用系统 Swift：Always Embed Swift Standard Libraries = NO，
// 且 LD_RUNPATH_SEARCH_PATHS 把 /usr/lib/swift 放在 @executable_path/Frameworks 前面。
// 嵌入旧版 libswiftCore 会与系统库重复实现 __SwiftNativeNSEnumeratorBase，真机 SIGABRT。
