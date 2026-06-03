import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const String storefrontMapUrl = 'https://maps.app.goo.gl/8ogwPYRF5gvkNEr3A';
const String storefrontAddress = 'Beller 8 local #2, Higuey 23000';
const String storefrontLocationTitle = 'FULLTECH SRL';
const String storefrontWhatsapp = '8494314070';
const String storefrontPhone = '8295319442';
const String storefrontEmail = 'fulltechsd@gmail.com';
const String storefrontInstagramHandle = 'fulltechsrl';
const String storefrontFacebookLabel = 'fulltech, srl';

const double storefrontLatitude = 18.6515456;
const double storefrontLongitude = -68.6620672;

class StorefrontMapView extends StatelessWidget {
  final double height;
  final bool compact;
  final BorderRadius borderRadius;
  final VoidCallback? onOpenExternal;

  const StorefrontMapView({
    super.key,
    required this.height,
    this.compact = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.onOpenExternal,
  });

  static Future<void> openStoreMap() async {
    await launchUrl(
      Uri.parse(storefrontMapUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = const LatLng(storefrontLatitude, storefrontLongitude);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          SizedBox(
            height: height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: compact ? 16.2 : 17.0,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
                onTap: (tapPosition, point) => onOpenExternal?.call(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fulltech.storefront',
                  panBuffer: 1,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 74,
                      height: 74,
                      child: _StoreMarker(compact: compact),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            right: compact ? 110 : 140,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storefrontLocationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      storefrontAddress,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onOpenExternal,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 10 : 12,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(Icons.near_me_rounded, size: compact ? 16 : 18),
              label: Text(compact ? 'Ir' : 'Como llegar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreMarker extends StatelessWidget {
  final bool compact;

  const _StoreMarker({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 18 : 20,
          height: compact ? 18 : 20,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                blurRadius: 14,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 12,
          ),
        ),
        Container(
          width: 3,
          height: compact ? 18 : 20,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }
}
