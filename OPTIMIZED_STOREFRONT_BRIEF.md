# FULLTECH Storefront Brief

## Goal
Redesign the main storefront screen for `FULLTECH SRL` so it feels premium, fast, trustworthy, and clearly mobile-first.

The page should immediately communicate:

`FULLTECH SRL sells technology professionally and can be trusted.`

## What Success Looks Like
- Clean visual hierarchy
- No repeated elements
- Strong first impression on mobile
- Fast image loading and smooth scrolling
- Clear pricing, offers, and actions
- Footer with real business identity
- WhatsApp and cart always easy to use

## Page Structure
1. Compact sticky app bar
2. Clean hero slider
3. Trust chips
4. Categories
5. Daily offers
6. Featured products
7. Full catalog
8. Professional footer
9. Floating WhatsApp button

## 1. App Bar
The app bar must be slim, elegant, and always useful.

### Include
- Drawer icon on the left
- Store name: `FULLTECH SRL`
- Compact search bar
- Cart icon on the right

### Rules
- Respect safe area
- Stay visually light
- Do not cover content
- Work well on small Android screens
- White or soft-glass background
- Soft shadow, premium feel

## 2. Hero Slider
The hero must sell visually, not repeat navigation.

### Show only
- Product or service image
- Short title
- Short supporting text
- Price or offer when relevant
- One clear CTA
- Page indicators

### Do not show
- Store name
- Search bar
- Drawer icon
- Cart icon
- Repeated header content

### Visual direction
- Rounded corners
- Strong but clean image composition
- Light overlay only when needed for readability
- Professional cropping
- Smooth horizontal transition
- No heavy animation

## 3. Trust Chips
Place compact trust signals below the hero, not inside it.

### Use
- Garantia
- Tienda fisica
- Soporte
- Instalacion disponible
- Entrega disponible
- Pago seguro

### Rules
- Compact
- No oversized pills
- No duplication elsewhere

## 4. Categories
Categories should feel useful and polished.

### Each category card should show
- Category image
- Category name
- Product count

### Rules
- Horizontal scroll
- Fixed mobile-friendly size
- Image fills well
- No broken layout

## 5. Daily Offers
This section must attract clicks quickly.

### Include
- Section title with icon
- `Ver todo` action
- Only real offer products

### Avoid
- Repeating the same products again in the catalog section
- Too many visual sale badges

## 6. Product Cards
Product cards must be easy to scan and easy to buy from.

### Each card must show
- Product image
- Availability state
- Offer badge if needed
- Product name
- Short description
- Current price
- Previous price if exists
- Discount if exists
- Cart action

### Interaction
- Allow changing between multiple product images inside the card
- Support swipe and arrow buttons
- Keep price visible at all times

### Layout rules
- 2 balanced columns on mobile
- Fixed image area
- Max 2 lines for long text
- Cart button must not cover price or description

## 7. WhatsApp Button
The WhatsApp button should stay visible and useful without blocking content.

### Link
`https://wa.me/18295344286?text=Hola,%20estoy%20viendo%20la%20tienda%20de%20FULLTECH%20SRL%20y%20quiero%20mas%20informacion.`

### Rules
- Bottom-right position
- Respect bottom safe area
- Soft pulse or entrance animation
- WhatsApp green
- Do not cover footer or product actions

## 8. Footer
The footer must feel corporate, compact, and real.

### Brand
- Show only: `FULLTECH SRL`
- If there is no valid logo, show no logo

### Main info
- Direccion: `Higuey centro, Beller 9 local 2`
- Telefono: `829-534-4286`
- WhatsApp access
- Brief business description

### "Trabajamos con"
- Sistemas de seguridad
- Software
- Computadoras
- Productos variados
- Motores para portones
- Camaras de seguridad

### Style
- Dark premium look
- Good spacing
- Not too tall
- Touch-friendly contact links

## 9. Performance
The screen must feel production-ready.

### Apply
- Image caching
- Lightweight placeholders or skeletons
- Smooth image fade-in
- Preload hero images when possible
- Avoid unnecessary rebuilds
- Avoid heavy blur and heavy shadows
- Keep scrolling smooth on Android

## 10. Responsive Rules
Design for phone first.

### Validate
- Small Android phones
- Large Android phones
- Devices with notch
- Devices with bottom system bar
- Long vertical scroll

### Use well
- `SafeArea`
- `MediaQuery`
- `LayoutBuilder`
- `CustomScrollView`
- `SliverAppBar` only if it improves the experience

## 11. Code Structure
Keep the home screen modular and maintainable.

### Recommended widgets
- `StorefrontAppBar`
- `StorefrontHeroSlider`
- `StorefrontTrustChips`
- `StorefrontCategorySection`
- `StorefrontProductGrid`
- `StorefrontProductCard`
- `StorefrontWhatsAppButton`
- `StorefrontFooter`

## 12. Acceptance Checklist
The work is only done when all of this is true:

- App bar looks clean on mobile
- Hero does not repeat app bar content
- Trust chips are compact and well placed
- Categories look full and professional
- Offer products are not duplicated in the catalog
- Product cards show image, text, and price correctly
- Product image arrows work
- WhatsApp button opens correctly
- Footer shows real FULLTECH identity
- No overflow or broken spacing
- No hidden content behind notch or bottom bar
- Screen feels fast and polished

## Final Direction
This should not feel like a basic Flutter shop page.

It should feel like a serious mobile storefront for a real company:

`clear, premium, fast, commercial, and trustworthy`
