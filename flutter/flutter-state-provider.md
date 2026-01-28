# Provider in Flutter

## Introduction

Provider is one of the most popular state management solutions in Flutter. With Provider, you can easily manage application state, dependencies, and rebuild only the widgets that need to be updated.

## What is Provider?

Provider is a state management library that makes it easy to:
- **Manage application state** efficiently
- **Inject dependencies** throughout your app
- **Rebuild only affected widgets** using consumers
- **Share data** between different parts of your application

Provider wraps Flutter's `InheritedWidget` and `ChangeNotifier` in a clean, easy-to-use API that reduces boilerplate and makes code more maintainable.

## Installation

Add Provider to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
```

Then run:
```bash
flutter pub get
```

## Core Concepts

### ChangeNotifier
`ChangeNotifier` is a simple class included in the Flutter SDK which provides change notification to its listeners, In other words, if something is a ChangeNotifier, you can subscribe to its changes.

For example, we want to manage the state of cart in a `ChangeNotifier`. We will create a new class that extend it, like so:

```dart
class CartModel extends ChangeNotifier {
  /// Internal, private state of the cart.
  final List<Item> _items = [];

  /// An unmodifiable view of the items in the cart.
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);

  /// The current total price of all items (assuming all items cost $42).
  int get totalPrice => _items.length * 42;

  /// Adds [item] to cart. This and [removeAll] are the only ways to modify the
  /// cart from the outside.
  void add(Item item) {
    _items.add(item);
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }

  /// Removes all items from the cart.
  void removeAll() {
    _items.clear();
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }
}

```

### ChangeNotifierProvider
`ChangeNotifierProvider`is the widget that provides an instance of a ChangeNotifier to its descendants.

We already know where to put `ChangeNotifierProvider`: above the widgets that need to access it. 

The root widget that holds all your providers. Usually placed at the top of your app:

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: const MyApp(),
    ),
  );
}
```

If you want to provide more than one class, you can use MultiProvider:

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        Provider(create: (context) => SomeOtherClass()),
      ],
      child: const MyApp(),
    ),
  );
}

```

### Consumer
A widget that listens to changes from a provider and rebuilds when data changes:

As our example, CartModel is provided to widgets in our app through the ChangeNotifierProvider declaration at the top, we can start using it.

This is done through the Consumer widget:

```dart
return Consumer<CartModel>(
  builder: (context, cart, child) {
    return Text('Total price: ${cart.totalPrice}');
  },
);
```

The only required argument of the `Consumer` widget is the builder. Builder is a function that is called whenever the `ChangeNotifier` changes. (In other words, when you call `notifyListeners()` in your model, all the builder methods of all the corresponding `Consumer` widgets are called.)

> It is best practice to put your `Consumer` widgets as deep in the tree as possible. You don't want to rebuild large portions of the UI just because some detail somewhere changed.

### Provider.of

Use this when you don't really need the data in the model to change the UI but you still need to access it. For example, a `ClearCart` button wants to allow the user to remove everything from the cart. It doesn't need to display the contents of the cart, it just needs to call the clear() method.

For this use case, we can use Provider.of, with the listen parameter set to false. We'd be asking the framework to rebuild a widget that doesn't need to be rebuilt.

```dart
Provider.of<CartModel>(context, listen: false).removeAll();
```