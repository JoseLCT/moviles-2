import 'package:flutter/material.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/product_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          getHeader(),
          getProductListView(),
        ],
      ),
    );
  }

  Widget getHeader() {
    return SliverAppBar(
      title: const Text('Marketplace'),
      floating: false,
      snap: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget getProductListView() {
    return FutureBuilder<List<Product>>(
      future: getProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return getProductView(snapshot.data?[index]);
              }, childCount: snapshot.data?.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2));
        } else if (snapshot.hasError) {
          return const SliverToBoxAdapter(child: Text('Error'));
        } else {
          return const SliverToBoxAdapter(child: Text('Loading... '));
        }
      },
    );
  }

  Widget getProductView(Product? product) {
    if (product == null) {
      return const Text('Error');
    }
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          //Image.network(product.productimages[0]),
          Text(product.name),
          Text(product.description),
          Text(product.price.toString()),
        ],
      ),
    );
  }
}
