CodeViewEditor-iOS
==================
Code Editor for iPhone &amp; iPad

Features:
- macro selection
- macro configuration
- comment, string, number, and keyword highlighting
- keystroke character replacement
- auto indent

![alt tag](https://raw.githubusercontent.com/PunchThrough/CodeViewEditor/master/iphoneScreenshot.png)

# Installation with CocoaPods 

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like the CodeViewEditor. See the ["Getting Started" guide for more information](https://github.com/PunchThrough/CodeViewEditor/wiki) on CocoaPods as well as an Example Project.

#### Podfile for iOS

```ruby
platform :ios, '7.0'
pod 'iOS-Rich-Text-Editor' , :git => 'https://github.com/aryaxt/iOS-Rich-Text-Editor.git', :commit => '4ddd86bbd6764d0a052ffa2db4e90037562162d6'
pod 'CodeTextEditor' , :git => 'https://github.com/PunchThrough/CodeTextEditor.git', :tag => '0.0.1'
```

Setting up Toolbar and Macros
-------------------------
The Toolbar is configured by menu~ipad.json / menu~iphone.json which are required to be in the main bundle. Let's take a look at a sample snippet. This will give you a toolbar with a Macro Selector on the left most side. If you select it, it provides a Serial category and selecting that gives the option of inserting the text Serial.read(), with an offset of cursor 13 characters, or at the end of our inserted text.

Next to the Macros is a `;` which is a quick way to select a `;`

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
Initialization is done by creating a `PTDCodeViewEditor` object and passing it config files. The syntax of the config files are described in the following sections and are assumed to be in the main bundle.

```objective-c
 NSString *textReplaceFile = @"textReplace";
 NSString *keywordsFile = @"keywords";
 NSString *textColorsFile = @"textColors";
 NSString *textSkipFile = @"textSkip";
 PTDCodeViewEditor *codeTextEditor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:40 textReplaceFile:textReplaceFile keywordsFile:@"keywords" textColorsFile:textColorsFile textSkipFile:textSkipFile];
```

Text Replacement
-------------------------
The text replacement file is used to replace entered characters. The example below replaced a typed `[` with `[]` and the cursor offset by one. The text replacement file is assumed to be JSON and end with `.json`.

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
The text colors file is used to color text. In the example below, the keyword with key `KEYWORD1` will be highlighted as RGB (0.2,0.2,0.2). 
- Comments are defined as anything between `//` and `/**/`
- Strings anything between `''` or `""`
- Invalid strings as unterminated strings
- Numbers as any base 10, hex or binary number. 

The text color is assumed to be JSON and end with `.json`.

```javascript
{
    "keywords":
    [{ "KEYWORD1":[0.2,0.2,0.2]}],
    "comments":[0.3,0.3,0.3],
    "string":[0,0.6,0.6],
    "invalid-string":[0.6,0.6,0],
    "number":[0.0,0.6,0.6],
}
```

Skipping Characters
-------------------------
The skipping characters file is used to skip characters when the entered text is the same as the next character. In the example below, if a `]` is typed and the next character is a `]`, no text is inserted and the cursor moves forward by the offset. The file is assumed to be JSON and end with `.json`.

```javascript
{"]": {"text":"]", "offset":"1"}}
```

API usage
-------------------------
Most text properties can be overriden. The example below changes comments to red, indentation to a space, and the `parseDelay` to 1 second. 

Since parsing takes place in a background thread, syntax highlighting can only be applied when the text is the same before and after the parse. It also happens after an arbitrary delay to detect an idle moment, since syntax highlighting can slow the main thread. So, based on this config below, if I type `/* typing real fast */` with no delay between typing, after the last `/` is typed, after 1 second, the text is checked for changes, and if there are no changes, the comment gets colored.


```objective-c
codeTextEditor.commentColor = [UIColor redColor];
codeTextEditor.indentation = @" ";
codeTextEditor.parseDelay = 1;
```

Event Delegation
-------------------------
By implementing `PTDCodeViewEditorEventsDelegate`, your view controller can receive delegate calls for two events:

* Keyboard opened: `- (void)openedKeyboardForEditor:(PTDCodeViewEditor *)editor;`
* Keyboard dismissed: `- (void)dismissedKeyboardForEditor:(PTDCodeViewEditor *)editor;`

These methods are both optional. They're useful if you want to tie app behavior to editor behavior, i.e. saving a document whenever the keyboard opens or is dismissed.

Here's an example of how you can use the EventsDelegate in your view controller:

```objective-c
//
//  ViewController.m
//

#import "ViewController.h"

@interface ViewController ()<PTDCodeViewEditorEventsDelegate>
@property (strong, nonatomic) PTDCodeViewEditor *codeTextEditor;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.codeTextEditor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:25 textReplaceFile:@"textReplace" keywordsFile:@"keywords" textColorsFile:@"textColors" textSkipFile:@"textSkip"];
    [self.codeTextEditor setEditorEventsDelegate:self];
    [self.view addSubview:self.codeTextEditor];

    // other setup goes here
}

- (void)openedKeyboardForEditor:(PTDCodeViewEditor *)editor
{
    NSLog(@"Opened keyboard for editor: %@", editor);
}

- (void)dismissedKeyboardForEditor:(PTDCodeViewEditor *)editor
{
    NSLog(@"Dismissed keyboard for editor: %@", editor);
}

@end
```

Included in this workspace's example app is [a view controller](blob/master/ViewController.m) that implements the EventsDelegate.

Object Model
-------------------------
The object model for the [Abstract syntax tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree) has at the top most level : comments, strings, and code. Siblings of code include keywords and numbers.  Look at `PTDCodeViewEditorParser` for a deeper dive or check out the image below.

![alt tag](https://raw.githubusercontent.com/PunchThrough/CodeViewEditor/master/objModel.png)

Attribution
-------------------------
If you use our SDK to build something cool, we'd appreciate it if you did the following:

 * Link to the Bean page ([http://punchthrough.com/bean/](http://punchthrough.com/bean/)). This could be your README.md file, your website's footer, your app's About page, or anywhere you think your users will see it. We appreciate these links because they help people discover the LightBlue Bean, and we want to everyone building something cool with the Bean.
 * Let us know what you've built! Our favorite part at Punch Through is when people tell us about projects they're building and what they've accomplished with our products. You could post on [Beantalk, our community forum](http://beantalk.punchthrough.com/), mention us on [Twitter @PunchThrough](http://twitter.com/punchthrough), or email us at [info@punchthrough.com](mailto:info@punchthrough.com).
 
Licensing
-------------------------
This SDK is covered under **The MIT License**. See `LICENSE.txt` for more details.

Credits
-------------------------
- [WEPopover](https://github.com/werner77/WEPopover) 
- [iOS-Rich-Text-Editor](https://github.com/aryaxt/iOS-Rich-Text-Editor) 
- [TextKit_LineNumbers](https://github.com/alldritt/TextKit_LineNumbers/)

