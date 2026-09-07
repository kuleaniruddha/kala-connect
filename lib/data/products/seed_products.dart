import '../../models/product_payload.dart';

/// Curated initial catalog representing traditional Indian GI and heritage crafts.
/// Provides rich, realistic e-commerce data for the Amazon-style marketplace.
abstract final class SeedProducts {
  static List<ProductPayload> get initialCatalog => <ProductPayload>[
        const ProductPayload(
          id: 'seed-terracotta-horse-01',
          name: 'Bankura Terracotta Sacred Horse (14-inch)',
          category: 'Terracotta & Clay',
          description:
              'Authentic Panchmura terracotta horse featuring erect ears and symmetric linear motifs. Hand-fired in traditional wood kilns with deep earthy red tones. Blessed with the GI tag of West Bengal.',
          suggestedPrice: 849,
          priceLow: 750,
          priceHigh: 1200,
          mrp: 1499,
          discountPercent: 43,
          currency: 'INR',
          tags: ['terracotta', 'clay', 'bankura', 'bengal', 'handcrafted', 'gi_craft'],
          moreInfo:
              'Material: Riverbed alluvial clay\nFiring technique: Open wood kiln\nCraft heritage: 300-year-old Panchmura tradition\nWeight: ~1.2 kg\nCare: Dust gently with a dry microfiber cloth.',
          artisanId: 'artisan-biren-kumbhakar',
          artisanName: 'Biren Kumbhakar',
          artisanLocation: 'Panchmura, Bankura, WB',
          rating: 4.9,
          reviewCount: 88,
          material: 'Alluvial Riverbed Clay',
          heroImagePath:
              'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1582293041079-7814c2f12063?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: true,
          comments: [
            NativeComment(
              author: 'Sunita Roy',
              message: 'The detailing on the ears and saddle is magnificent. True Bengal folk heritage!',
              languageCode: 'en',
            ),
            NativeComment(
              author: 'Aakash Verma',
              message: 'पैकिंग बहुत मजबूत थी और कारीगरी बेमिसाल है।',
              languageCode: 'hi',
            ),
          ],
        ),
        const ProductPayload(
          id: 'seed-madhubani-canvas-02',
          name: 'Madhubani Hand-painted Tree of Life Silk Canvas',
          category: 'Folk Paintings',
          description:
              'Intricate Kachni and Bharni style painting made with bamboo nibs and natural mineral dyes extracted from indigo, marigold flowers, and turmeric. Depicts the sacred Tree of Life surrounded by dancing peacocks.',
          suggestedPrice: 1299,
          priceLow: 1100,
          priceHigh: 1800,
          mrp: 2200,
          discountPercent: 41,
          currency: 'INR',
          tags: ['madhubani', 'mithila', 'canvas', 'folk_art', 'bihar', 'natural_dyes'],
          moreInfo:
              'Base: Handmade tussar silk fabric canvas\nDyes: Natural extracted vegetable & mineral pigments\nStyle: Mithila Kachni line art\nDimensions: 18 x 24 inches\nFrame: Unframed canvas rolled in secure cardboard tube.',
          artisanId: 'artisan-ganga-devi',
          artisanName: 'Ganga Devi & Family',
          artisanLocation: 'Ranti Village, Madhubani, Bihar',
          rating: 5.0,
          reviewCount: 142,
          material: 'Handmade Silk & Botanical Pigments',
          heroImagePath:
              'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1582560475093-ba66accbc424?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: true,
          comments: [
            NativeComment(
              author: 'Priya Narayanan',
              message: 'You can smell the natural plant dyes! Such an extraordinary level of patience.',
              languageCode: 'en',
            ),
            NativeComment(
              author: 'सुमन मिश्रा',
              message: 'मधुबनी की असली पहचान। हर रेखा में आत्मा बसती है।',
              languageCode: 'hi',
            ),
          ],
        ),
        const ProductPayload(
          id: 'seed-dhokra-musician-03',
          name: 'Bastar Lost-Wax Dhokra Brass Musician Figurine',
          category: 'Metal & Brass',
          description:
              'Ancient 4,000-year-old lost-wax (Cire-Perdue) casting technique by tribal artisans of Bastar. Cast in non-ferrous bell metal with ornate braided wire texture portraying a traditional dholak player.',
          suggestedPrice: 950,
          priceLow: 850,
          priceHigh: 1400,
          mrp: 1750,
          discountPercent: 46,
          currency: 'INR',
          tags: ['dhokra', 'bastar', 'brass', 'metal_craft', 'tribal', 'lost_wax'],
          moreInfo:
              'Process: Beeswax modeling, clay moulding, molten bell metal casting\nMaterial: Brass and bell-metal alloy\nWeight: 780 grams\nDimensions: 7 inches height.',
          artisanId: 'artisan-sukru-ram',
          artisanName: 'Sukru Ram Ghadwa',
          artisanLocation: 'Kondagaon, Bastar, Chhattisgarh',
          rating: 4.8,
          reviewCount: 65,
          material: 'Bell Metal Brass Alloy',
          heroImagePath:
              'https://images.unsplash.com/photo-1606722590583-3caa991d0bdf?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1606722590583-3caa991d0bdf?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1603204077779-bed963ea7d0d?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: true,
          comments: [
            NativeComment(
              author: 'Devendra K.',
              message: 'Heavier than I thought and remarkably detailed wire-work on the tribal headgear.',
              languageCode: 'en',
            ),
          ],
        ),
        const ProductPayload(
          id: 'seed-blue-pottery-vase-04',
          name: 'Jaipur Turquoise Blue Pottery Hand-Glazed Floral Vase',
          category: 'Pottery & Ceramics',
          description:
              'Traditional quartz-based Egyptian blue glaze pottery crafted without clay. Hand-decorated by master artisans with cobalt blue Persian motifs and blooming lotus patterns.',
          suggestedPrice: 720,
          priceLow: 600,
          priceHigh: 1100,
          mrp: 1250,
          discountPercent: 42,
          currency: 'INR',
          tags: ['blue_pottery', 'jaipur', 'rajasthan', 'ceramic', 'hand_painted', 'vase'],
          moreInfo:
              'Composition: Quartz stone powder, glass, Multani mitti, and gum (Zero clay)\nKiln firing: Low fire 800°C\nWater capacity: 800 ml (Glazed interior)\nHeight: 9 inches.',
          artisanId: 'artisan-kailash-prajapati',
          artisanName: 'Kailash Chand Prajapati',
          artisanLocation: 'Kot Jewar, Jaipur, Rajasthan',
          rating: 4.7,
          reviewCount: 94,
          material: 'Glazed Quartz Composite',
          heroImagePath:
              'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: false,
          comments: [
            NativeComment(
              author: 'Meera Rao',
              message: 'Brings authentic Rajasthani palace vibes to my living room table.',
              languageCode: 'en',
            ),
          ],
        ),
        const ProductPayload(
          id: 'seed-channapatna-toys-05',
          name: 'Channapatna Eco-friendly Lacquer Wooden Stacking Rings',
          category: 'Wooden Craft',
          description:
              'Non-toxic organic wooden toy turned on traditional lathes using soft Hale wood and coloured with natural vegetable dyes (turmeric, kumkum, indigo). Child-safe and GI protected.',
          suggestedPrice: 490,
          priceLow: 400,
          priceHigh: 750,
          mrp: 899,
          discountPercent: 45,
          currency: 'INR',
          tags: ['channapatna', 'wooden_toy', 'karnataka', 'natural_lacquer', 'safe_for_kids'],
          moreInfo:
              'Wood: Wrightia tinctoria (Aale mara)\nColors: Edible food & plant extracts\nSafety: 100% lead-free, rounded smooth edges\nRecommended age: 1 year and above.',
          artisanId: 'artisan-syed-khader',
          artisanName: 'Syed Khader',
          artisanLocation: 'Channapatna, Ramanagara, Karnataka',
          rating: 4.9,
          reviewCount: 112,
          material: 'Ivory Wood & Organic Lacquer',
          heroImagePath:
              'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: false,
          comments: [
            NativeComment(
              author: 'Rohit Shenoy',
              message: 'Much better than cheap plastic toys. Silky smooth finish!',
              languageCode: 'en',
            ),
          ],
        ),
        const ProductPayload(
          id: 'seed-kantha-textile-06',
          name: 'Hand-embroidered Bengal Kantha Stitch Pure Tussar Dupatta',
          category: 'Textiles & Handloom',
          description:
              'Meticulously hand-embroidered by women artisans in rural Shantiniketan. Features centuries-old Nakshi Kantha running stitches depicting village life, lotus ponds, and peacocks.',
          suggestedPrice: 1650,
          priceLow: 1400,
          priceHigh: 2400,
          mrp: 2999,
          discountPercent: 45,
          currency: 'INR',
          tags: ['kantha', 'tussar_silk', 'hand_embroidered', 'shantiniketan', 'bengal'],
          moreInfo:
              'Fabric: 100% Pure Murshidabad Tussar Silk\nEmbroidery work: 45 days of continuous needlework\nLength: 2.4 meters\nWash care: Dry clean only.',
          artisanId: 'artisan-fatema-khatun',
          artisanName: 'Fatema Khatun Self-Help Group',
          artisanLocation: 'Bolpur, Shantiniketan, WB',
          rating: 4.9,
          reviewCount: 76,
          material: 'Pure Tussar Silk & Cotton Threads',
          heroImagePath:
              'https://images.unsplash.com/photo-1603204077779-bed963ea7d0d?auto=format&fit=crop&w=900&q=80',
          cleanHeroImagePath:
              'https://images.unsplash.com/photo-1603204077779-bed963ea7d0d?auto=format&fit=crop&w=900&q=80',
          additionalImages: [
            'https://images.unsplash.com/photo-1606722590583-3caa991d0bdf?auto=format&fit=crop&w=800&q=80',
          ],
          isFeatured: true,
          comments: [
            NativeComment(
              author: 'Ananya Sen',
              message: 'The silk drape is so regal and every stitch tells a story of perseverance.',
              languageCode: 'en',
            ),
          ],
        ),
      ];
}
