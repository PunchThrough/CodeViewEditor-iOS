CodeViewEditor-iOS
==================
Code Editor for iPhone &amp; iPad

Features:
- macro selection
- macro configuratin
- comment, string, number, and keyword highlighting
- keystroke character replacement
- auto indent

![alt tag](https://raw.githubusercontent.com/PunchThrough/CodeViewEditor/master/iphoneScreenshot.png)

# Installation with CocoaPods 

[CocoaPods](http://cocoapods.org)  is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like the CodeViewEditor. 

#### Podfile for iOS

```ruby
platform :ios, '7.0'
pod 'iOS-Rich-Text-Editor' , :git => 'https://github.com/aryaxt/iOS-Rich-Text-Editor.git', :commit => '4ddd86bbd6764d0a052ffa2db4e90037562162d6'
pod 'CodeTextEditor' , :git => 'https://github.com/PunchThrough/CodeTextEditor.git', :tag => '0.0.1'
```














Custom Font Size Selection
-------------------------
Font size selection can be customized by implementing the following data source method

```objective-c
- (NSArray *)fontSizeSelectionForRichTextEditor:(RichTextEditor *)richTextEditor
{
	// pas an array of NSNumbers
	return @[@5, @10, @20, @30];
}
```

Custom Font Family Selection
-------------------------
Font family selection can be customized by implementing the following data source method

```objective-c
- (NSArray *)fontFamilySelectionForRichTextEditor:(RichTextEditor *)richTextEditor
{
	// pas an array of Strings
  // Can be taken from [UIFont familyNames]
	return @[@"Helvetica", @"Arial", @"Marion", @"Papyrus"];
}
```

Presentation Style
-------------------------
You can switch between popover, or modal (presenting font-picker, font-size-picker, color-picker dialogs) by implementing the following data source method
```objective-c
- (RichTextEditorToolbarPresentationStyle)presentarionStyleForRichTextEditor:(RichTextEditor *)richTextEditor
{
  // RichTextEditorToolbarPresentationStyleModal Or RichTextEditorToolbarPresentationStylePopover
	return RichTextEditorToolbarPresentationStyleModal;
}
```

Modal Presentation Style
-------------------------
When presentarionStyleForRichTextEditor is a modal, modal-transition-style & modal-presentation-style can be configured
```objective-c
- (UIModalPresentationStyle)modalPresentationStyleForRichTextEditor:(RichTextEditor *)richTextEditor
{
	return UIModalPresentationFormSheet;
}

- (UIModalTransitionStyle)modalTransitionStyleForRichTextEditor:(RichTextEditor *)richTextEditor
{
	return UIModalTransitionStyleFlipHorizontal;
}
```

Customizing Features
-------------------------
Features can be turned on/off by iplementing the following data source method
```objective-c
- (RichTextEditorFeature)featuresEnabledForRichTextEditor:(RichTextEditor *)richTextEditor
{
   return RichTextEditorFeatureFont | 
          RichTextEditorFeatureFontSize |
          RichTextEditorFeatureBold |
          RichTextEditorFeatureParagraphIndentation;
}
```

Enable/Disable RichText Toolbar
-------------------------
You can hide the rich text toolbar by implementing the following method. This method gets called everytime textView becomes first responder.
This can be usefull when you don't want the toolbar, instead you want to use the basic features (bold, italic, underline, strikeThrough), thoguht the UIMeMenuController
```objective-c
- (BOOL)shouldDisplayToolbarForRichTextEditor:(RichTextEditor *)richTextEditor
{
   return YES;
} 
```

Enable/Disable UIMenuController Options
-------------------------
On default the UIMenuController options (bold, italic, underline, strikeThrough) are turned off. You can implement the follwing method if you want these features to be available through the UIMenuController along with copy/paste/selectAll etc.
```objective-c
- (BOOL)shouldDisplayRichTextOptionsInMenuControllerForRichTextrEditor:(RichTextEditor *)richTextEdiotor
{
   return YES;
} 
```

Credits
-------------------------
iPhone popover by werner77
https://github.com/werner77/WEPopover
