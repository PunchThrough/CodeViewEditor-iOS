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

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like the CodeViewEditor. See the ["Getting Started" guide for more information](https://github.com/PunchThrough/CodeViewEditor/wiki) on CocoaPods as well as Example Project.

#### Podfile for iOS

```ruby
platform :ios, '7.0'
pod 'iOS-Rich-Text-Editor' , :git => 'https://github.com/aryaxt/iOS-Rich-Text-Editor.git', :commit => '4ddd86bbd6764d0a052ffa2db4e90037562162d6'
pod 'CodeTextEditor' , :git => 'https://github.com/PunchThrough/CodeTextEditor.git', :tag => '0.0.1'
```

Setting up Toolbar and Macros
-------------------------
The Toolbar is configured by menu~ipad.json / menu~iphone.json which are required to be in the main bundle. Let's take a look at a sample snippet. This will give you a toolbar with a Macro Selector on the left most side. If you select it, it provides a Serial category and selecting that gives the option of inserting Serial.read(), with an offset of cursor 13 characters, or at the end of our inserted text.

Next to the Macros is a ; which is a quick way to select a ;

```javascript
 [{
  "text":"Macros",
  "width":72,
  "type":"category",
  "children":[{"text":"Serial",
               "type":"category",
               "children":[{"text":"Serial.read()",
                           "type":"text",
                           "value":"Serial.read()",
                           "offset":13}]}]
  },{
  "text":";",
  "width":44,
  "type":"text",
  "value":";",
  "offset":1
}]
```

More examples of the menu configuration as well as initialization and API usage are in the Example Project described at the bottom of the [Getting Started Guide](https://github.com/PunchThrough/CodeViewEditor/wiki).

Initialization
-------------------------
Initialization is done by creating a PTDCodeViewEditor object and passing it config files. The syntax of the config files are described in the following sections. 

```objective-c
 NSString *textReplaceFile = @"textReplace";
 NSString *keywordsFile = @"keywords";
 NSString *textColorsFile = @"textColors";
 NSString *textSkipFile = @"textSkip";
 PTDCodeViewEditor *codeTextEditor = [[PTDCodeViewEditor alloc] initWithLineNumbers:YES textReplaceFile:textReplaceFile keywordsFile:@"keywords" textColorsFile:textColorsFile textSkipFile:textSkipFile];
```

Text Replacement
-------------------------
The text replacment file is used to replace entered characters. The example below replaced a typed `[` with `[]` with the cursor offset by one. The text replacement is assumed to be JSON and end with `.json`.

```javascript
[{
  "text":"[",
  "value":"[]",
  "offset":1
}]
```

Keywords
-------------------------
The keywords file is a tab delimted file where the first token is the keyword and the second value is the keyword attribute. If the keyword attribute is empty, a the third tab delimited value is checked. In the example below, `boolean`, `break` and `HIGH` are checked and their attributes matched to the Text Colors file. The keywords file is assumed to be a text file and end with `.txt`.

```javascript
{
boolean	KEYWORD1
break	KEYWORD2
HIGH	LITERAL1
}
```

Text Colors
-------------------------
The text colors file is used to syntax highlight text. In the example below, the keyword with key `KEYWORD1` will be highlighted as RGB (0.2,0.2,0.2). Comments are defined as anything between `//` and `/**/`, strings anything between `''` or `""`, invalid strings as unterminated strings, and numbers as any base 10, hex or binary number. The text color is assumed to be JSON and end with `.json`.

```javascript
{
    "keywords":
    [{ "KEYWORD1":[0.2,0.4,0.4]}],
    "comments":[0.3,0.3,0.3],
    "string":[0,0.6,0.6],
    "invalid-string":[0.6,0.6,0],
    "number":[0.0,0.6,0.6],
}
```

Skipping Characters
-------------------------
The skipping characters file is used to skip characters when the entered text is the same as the next character. In the example below, if a `]` is typed and the next character is a `]`, no text is inserted and the cursor moves forward by the offset.

```javascript
{"]": {"text":"]", "offset":"1"}}
```

API usage
-------------------------
Most text properties can be overriden. The example below changes comments to red, the indent to a space, and the parseDelay to 1 second. 

Since parsing takes place in a background thread, we can only apply new syntax highlighting if the text is the same as it was when parsing began. Part of the reason is the coloring can hold up the main thread, which is not ideal. So, we wait until an idle moment to apply the coloring.

```objective-c
codeTextEditor.commentColor = [UIColor redColor];
codeTextEditor.indentation = @" ";
codeTextEditor.parseDelay = 1;
```

Object Model
-------------------------
The object model for the [Abstract syntax tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree) starts with comments and strings as the top most segments, followed by keywords and numbers as siblings. For more details, look at `PTDCodeViewEditorParser`

![alt tag](https://raw.githubusercontent.com/PunchThrough/CodeViewEditor/master/objModel.png)
