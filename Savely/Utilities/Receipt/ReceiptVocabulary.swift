//
//  ReceiptVocabulary.swift
//  Savely
//
//  The words the parser looks for on es-MX / en-US receipts, in one place:
//  which labels mean "this is what you paid", which mean "this is NOT it"
//  (subtotal, tax, cash tendered, change, tip…), the brands we recognise,
//  and the keywords that hint at one of the five expense chips.
//
//  All matching happens on `ReceiptText.normalized(_:)` output: uppercase,
//  accents folded, punctuation collapsed to spaces, padded with one space
//  on each side — so `" TOTAL "` matches the word and not `SUBTOTAL`.
//

import Foundation

enum ReceiptText {
    /// Uppercases, folds accents (`CAMBIÓ` → `CAMBIO`), turns every
    /// non-alphanumeric character into a space (`SUB-TOTAL:` → `SUB TOTAL`),
    /// collapses runs of spaces, and pads the result with a single space on
    /// both ends so callers can match whole words with `contains(" WORD ")`.
    static func normalized(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .uppercased()
        var out = " "
        var lastWasSpace = true
        for scalar in folded.unicodeScalars {
            let isAlnum = CharacterSet.alphanumerics.contains(scalar)
            if isAlnum {
                out.unicodeScalars.append(scalar)
                lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" ")
                lastWasSpace = true
            }
        }
        if !lastWasSpace { out.append(" ") }
        return out
    }

    /// True when the padded, normalized `haystack` contains `phrase` as
    /// whole words. `phrase` is written in normal form already (uppercase,
    /// single spaces, no accents).
    static func containsPhrase(_ haystack: String, _ phrase: String) -> Bool {
        haystack.contains(" \(phrase) ")
    }
}

/// How a row's label relates to the amount printed on it.
enum ReceiptLabelClass: Equatable {
    /// "TOTAL A PAGAR", "GRAND TOTAL", "AMOUNT DUE" — the strongest signal.
    case totalStrong
    /// "TOTAL", "IMPORTE" — what most receipts print.
    case total
    /// "TOTAL CON PROPINA" / "TOTAL WITH TIP" — a real total, but usually not
    /// the one the user thinks of first; kept as an alternative.
    case totalWithTip
    /// Subtotal / tax / cash tendered / change / card / points… — an amount
    /// that must never be picked as the total.
    case excluded(ReceiptExclusion)
    case none
}

/// Why an amount is excluded — some exclusions feed the math check.
enum ReceiptExclusion: Equatable {
    case subtotal
    case tax
    case tip
    case cash
    case change
    case card
    case other
}

enum ReceiptVocabulary {
    // MARK: Labels

    /// Ordered from most to least specific: the first phrase that matches
    /// decides the class. Phrases are in `ReceiptText.normalized` form.
    static let totalStrongPhrases: [String] = [
        "TOTAL A PAGAR", "TOTAL PAGAR", "IMPORTE TOTAL", "IMPORTE A PAGAR", "GRAN TOTAL",
        "GRAND TOTAL", "AMOUNT DUE", "BALANCE DUE", "TOTAL DUE", "TOTAL VENTA", "TOTAL DE LA VENTA",
        "TOTAL COMPRA", "TOTAL FACTURA", "TOTAL TICKET", "TOTAL NOTA", "TOTAL GENERAL",
    ]
    static let totalWithTipPhrases: [String] = [
        "TOTAL CON PROPINA", "TOTAL C PROPINA", "TOTAL PROPINA INCLUIDA", "TOTAL WITH TIP",
        "TOTAL WITH GRATUITY", "TOTAL INCL TIP",
    ]
    /// Rows that say TOTAL together with a payment/tax word and still mean
    /// "what you paid" — checked BEFORE the exclusions so "TOTAL PAGADO" or
    /// "TOTAL IVA INCLUIDO" are not demoted by PAGADO / IVA.
    static let totalOverridePhrases: [String] = [
        "TOTAL IVA INCLUIDO", "TOTAL CON IVA", "TOTAL INCLUYE IVA", "TOTAL INC IVA", "TOTAL PAGADO",
        "TOTAL PAID", "TOTAL PAGO", "TOTAL TARJETA", "TOTAL CARD", "TOTAL EFECTIVO", "TOTAL CASH",
        "TOTAL COBRADO", "TOTAL CHARGED", "IMPORTE PAGADO", "IMPORTE COBRADO",
    ]
    static let totalPhrases: [String] = [
        "TOTAL", "T0TAL", "TOTAL MXN", "TOTAL USD", "TOTAL MN", "TOTAL M N", "TOTAL DLLS", "TOTAL PESOS",
        "IMPORTE", "A PAGAR", "MONTO TOTAL", "MONTO", "NETO A PAGAR", "TOTAL NETO",
    ]

    /// Exclusions checked BEFORE the total phrases (so "SUBTOTAL" and
    /// "TOTAL ARTICULOS" never count as a total). Order matters only within
    /// a class; the first hit wins.
    static let exclusionPhrases: [(phrase: String, kind: ReceiptExclusion)] = [
        ("SUBTOTAL", .subtotal), ("SUB TOTAL", .subtotal), ("SUBT0TAL", .subtotal), ("SUBTOT", .subtotal),
        ("SUB TOT", .subtotal), ("SUBTOTALES", .subtotal),
        ("IVA", .tax), ("I V A", .tax), ("IEPS", .tax), ("TAX", .tax), ("TAXES", .tax), ("VAT", .tax),
        ("SALES TAX", .tax), ("IMPUESTO", .tax), ("IMPUESTOS", .tax), ("BASE GRAVABLE", .tax), ("TASA", .tax),
        ("PROPINA", .tip), ("TIP", .tip), ("GRATUITY", .tip), ("SERVICIO", .tip),
        ("EFECTIVO", .cash), ("CASH", .cash), ("PAGO EN EFECTIVO", .cash), ("RECIBIDO", .cash),
        ("SU PAGO", .cash), ("TENDERED", .cash), ("TENDER", .cash), ("TEND", .cash), ("PAGO", .cash),
        ("PAGADO", .cash), ("PAID", .cash), ("RECIBIMOS", .cash), ("ENTREGADO", .cash),
        ("CAMBIO", .change), ("CHANGE", .change), ("SU CAMBIO", .change), ("VUELTO", .change),
        ("TARJETA", .card), ("CARD", .card), ("VISA", .card), ("MASTERCARD", .card), ("AMEX", .card),
        ("DEBITO", .card), ("CREDITO", .card), ("DEBIT", .card), ("CREDIT", .card), ("TDC", .card),
        ("TDD", .card), ("APPLE PAY", .card), ("CLIP", .card), ("TERMINAL", .card), ("APROBADO", .card),
        ("AUTORIZACION", .card), ("AUTH", .card), ("AUTORIZ", .card),
        ("PUNTOS", .other), ("POINTS", .other), ("AHORRO", .other), ("AHORRASTE", .other), ("SAVINGS", .other),
        ("YOU SAVED", .other), ("DESCUENTO", .other), ("DESCUENTOS", .other), ("DISCOUNT", .other),
        ("ARTICULOS", .other), ("ARTICULO", .other), ("ITEMS", .other), ("ITEM COUNT", .other),
        ("PIEZAS", .other), ("PZAS", .other), ("UNIDADES", .other), ("QTY", .other), ("CANTIDAD", .other),
        ("SALDO", .other), ("BALANCE ANTERIOR", .other), ("REDONDEO", .other), ("DONATIVO", .other),
        ("DONACION", .other), ("ENVIO", .other), ("SHIPPING", .other), ("DELIVERY", .other),
        ("COMISION", .other), ("FEE", .other), ("CARGO", .other), ("PRECIO UNITARIO", .other),
        ("PRECIO", .other), ("P UNIT", .other), ("TIPO DE CAMBIO", .other),
        ("FOLIO", .other), ("TICKET", .other), ("CAJA", .other), ("CAJERO", .other),
        ("RFC", .other), ("REFERENCIA", .other),
        ("HORA", .other), ("FECHA", .other), ("DATE", .other), ("TIME", .other), ("CLIENTE", .other),
        ("SUCURSAL", .other), ("TIENDA", .other), ("STORE", .other),
    ]

    /// Classifies a normalized row string.
    static func labelClass(of normalizedRow: String) -> ReceiptLabelClass {
        for phrase in totalWithTipPhrases where ReceiptText.containsPhrase(normalizedRow, phrase) {
            return .totalWithTip
        }
        for phrase in totalStrongPhrases where ReceiptText.containsPhrase(normalizedRow, phrase) {
            return .totalStrong
        }
        // A total-strong or override phrase beats an exclusion word on the
        // same row ("TOTAL A PAGAR CON TARJETA", "TOTAL PAGADO" are still the
        // total); anything else with an exclusion word is out.
        for phrase in totalOverridePhrases where ReceiptText.containsPhrase(normalizedRow, phrase) {
            return .total
        }
        for entry in exclusionPhrases where ReceiptText.containsPhrase(normalizedRow, entry.phrase) {
            return .excluded(entry.kind)
        }
        for phrase in totalPhrases where ReceiptText.containsPhrase(normalizedRow, phrase) {
            return .total
        }
        return .none
    }

    /// Words that, when the whole row is only these plus digits, mark it as
    /// noise for merchant detection (greetings, document words, headers).
    static let merchantNoiseWords: Set<String> = [
        "BIENVENIDO", "BIENVENIDOS", "WELCOME", "GRACIAS", "THANK", "THANKS", "YOU", "POR", "SU", "COMPRA",
        "VISITA", "VUELVA", "PRONTO", "TICKET", "TIKET", "FACTURA", "NOTA", "DE", "VENTA", "COMPROBANTE",
        "ORIGINAL", "COPIA", "CLIENTE", "RECIBO", "RECEIPT", "INVOICE", "ORDER", "ORDEN", "PEDIDO", "MESA",
        "TABLE", "MESERO", "SERVER", "CAJA", "CAJERO", "CASHIER", "REGISTER", "FOLIO", "NO", "NUM", "SUC",
        "SUCURSAL", "TIENDA", "STORE", "TEL", "TELEFONO", "PHONE", "RFC", "R", "F", "C", "CP", "COL",
        "COLONIA", "CALLE", "AV", "AVE", "AVENIDA", "BLVD", "BOULEVARD", "CARRETERA", "KM", "LOCAL", "PLAZA",
        "MEXICO", "TIJUANA", "B", "BC", "BAJA", "CALIFORNIA", "CA", "USA", "SAN", "DIEGO", "CHULA", "VISTA",
        "WWW", "COM", "MX", "HTTP", "HTTPS", "FECHA", "HORA", "DATE", "TIME", "TERMINAL", "OPERADOR",
        "ATENDIO", "LE", "ATENDIO", "VENDEDOR", "TRANSACCION", "TRANS", "AUTORIZACION", "APROBADA",
        "DUPLICADO", "REIMPRESION", "PAGINA", "PAGE",
    ]

    /// Row-level markers that disqualify a row as the merchant name.
    static let merchantDisqualifiers: [String] = [
        "RFC", "R F C", "TEL", "TELEFONO", "PHONE", "CALLE", "AV", "AVE", "AVENIDA", "BLVD", "COL", "COLONIA",
        "C P", "CP", "FOLIO", "TICKET", "CAJA", "CAJERO", "FECHA", "HORA", "DATE", "TIME", "WWW", "COM",
        "SUCURSAL", "TIENDA", "STORE", "MESA", "MESERO", "ORDEN", "ORDER", "CLIENTE", "TERMINAL", "GRACIAS",
        "THANK", "BIENVENIDO", "BIENVENIDOS", "WELCOME", "NOTA DE VENTA", "COMPROBANTE", "FACTURA", "IVA",
        "SUBTOTAL", "TOTAL", "IMPORTE", "EFECTIVO", "CAMBIO", "PROPINA", "TARJETA", "PAGO", "CANT",
        "DESCRIPCION", "DESCRIPTION", "PRECIO", "PRICE", "QTY", "ARTICULO", "CODIGO", "SKU",
    ]

    /// Column headers ("CANT  DESCRIPCION  IMPORTE"): a label-less row made of
    /// these must not lend its IMPORTE to the item row below.
    static let columnHeaderWords: [String] = [
        "CANT", "CANTIDAD", "DESCRIPCION", "DESCRIPTION", "ARTICULO", "ARTICULOS", "PRODUCTO", "CONCEPTO",
        "PRECIO", "P UNIT", "PU", "QTY", "ITEM", "ITEMS", "UNIT", "UNIDAD", "CODIGO", "SKU", "DESC",
    ]

    /// Legal suffixes trimmed from a merchant name before it is shown.
    static let legalSuffixes: [String] = [
        "S A DE C V", "SA DE CV", "S DE RL DE CV", "S DE R L DE C V", "S A P I DE C V", "SAPI DE CV",
        "S C", "SC", "A C", "AC", "S A", "SA", "INC", "LLC", "LTD", "CORP", "CO",
    ]

    // MARK: Brands

    /// Canonical brand names keyed by the phrase that appears on the
    /// receipt (normalized form). Razones sociales map to the store people
    /// know. Longer phrases first so "UBER EATS" wins over "UBER".
    static let brands: [(phrase: String, name: String)] = [
        ("CADENA COMERCIAL OXXO", "OXXO"), ("OXXO", "OXXO"),
        ("NUEVA WAL MART DE MEXICO", "Walmart"), ("WAL MART", "Walmart"), ("WALMART", "Walmart"),
        ("BODEGA AURRERA", "Bodega Aurrerá"), ("SAM S CLUB", "Sam's Club"), ("SAMS CLUB", "Sam's Club"),
        ("SUPERAMA", "Superama"),
        ("TIENDAS SORIANA", "Soriana"), ("SORIANA", "Soriana"),
        ("COSTCO WHOLESALE", "Costco"), ("COSTCO", "Costco"),
        ("H E B", "H-E-B"), ("HEB", "H-E-B"),
        ("TIENDAS CHEDRAUI", "Chedraui"), ("CHEDRAUI", "Chedraui"),
        ("CALIMAX", "Calimax"), ("SMART FINAL", "Smart & Final"), ("SMART AND FINAL", "Smart & Final"),
        ("CASA LEY", "Casa Ley"), ("LA COMER", "La Comer"), ("CITY MARKET", "City Market"),
        ("7 ELEVEN", "7-Eleven"), ("SEVEN ELEVEN", "7-Eleven"), ("CIRCLE K", "Circle K"),
        ("STARBUCKS", "Starbucks"), ("TIM HORTONS", "Tim Hortons"), ("PUNTA DEL CIELO", "Punta del Cielo"),
        ("CIELITO QUERIDO", "Cielito Querido"), ("DUTCH BROS", "Dutch Bros"), ("PEET S", "Peet's"),
        ("UBER EATS", "Uber Eats"), ("UBER", "Uber"), ("DIDI FOOD", "DiDi Food"), ("DIDI", "DiDi"),
        ("RAPPI", "Rappi"), ("LYFT", "Lyft"),
        ("MCDONALD S", "McDonald's"), ("MCDONALDS", "McDonald's"), ("BURGER KING", "Burger King"),
        ("CARL S JR", "Carl's Jr."), ("CARLS JR", "Carl's Jr."), ("KFC", "KFC"), ("SUBWAY", "Subway"),
        ("DOMINO S", "Domino's"), ("DOMINOS", "Domino's"), ("LITTLE CAESARS", "Little Caesars"),
        ("PIZZA HUT", "Pizza Hut"), ("CHIPOTLE", "Chipotle"), ("IN N OUT", "In-N-Out"), ("VIPS", "Vips"),
        ("TOKS", "Toks"), ("SANBORNS", "Sanborns"), ("EL POLLO LOCO", "El Pollo Loco"),
        ("PANDA EXPRESS", "Panda Express"), ("TACO BELL", "Taco Bell"), ("WENDY S", "Wendy's"),
        ("PEMEX", "Pemex"), ("CHEVRON", "Chevron"), ("SHELL", "Shell"), ("ARCO", "ARCO"), ("MOBIL", "Mobil"),
        ("AMAZON", "Amazon"), ("LIVERPOOL", "Liverpool"), ("COPPEL", "Coppel"), ("ELEKTRA", "Elektra"),
        ("SUBURBIA", "Suburbia"), ("SEARS", "Sears"), ("ZARA", "Zara"), ("H M", "H&M"), ("TARGET", "Target"),
        ("HOME DEPOT", "Home Depot"), ("BEST BUY", "Best Buy"), ("APPLE STORE", "Apple"), ("IKEA", "IKEA"),
        ("ROSS DRESS FOR LESS", "Ross"), ("MARSHALLS", "Marshalls"), ("TJ MAXX", "T.J. Maxx"),
        ("TRADER JOE S", "Trader Joe's"), ("TRADER JOES", "Trader Joe's"), ("ALDI", "Aldi"),
        ("KROGER", "Kroger"), ("VONS", "Vons"), ("RALPHS", "Ralphs"), ("SAFEWAY", "Safeway"),
        ("WHOLE FOODS", "Whole Foods"), ("SPROUTS", "Sprouts"), ("FOOD 4 LESS", "Food 4 Less"),
        ("FARMACIAS GUADALAJARA", "Farmacias Guadalajara"), ("FARMACIAS SIMILARES", "Farmacias Similares"),
        ("FARMACIAS BENAVIDES", "Farmacias Benavides"), ("FARMACIA DEL AHORRO", "Farmacias del Ahorro"),
        ("FARMACIAS DEL AHORRO", "Farmacias del Ahorro"), ("FARMACIA SAN PABLO", "Farmacia San Pablo"),
        ("CVS", "CVS"), ("WALGREENS", "Walgreens"), ("RITE AID", "Rite Aid"),
        ("CINEPOLIS", "Cinépolis"), ("CINEMEX", "Cinemex"), ("AMC", "AMC"),
        ("OFFICE DEPOT", "Office Depot"), ("OFFICEMAX", "OfficeMax"), ("STAPLES", "Staples"),
        ("TELCEL", "Telcel"), ("AT T", "AT&T"), ("TOTALPLAY", "Totalplay"), ("IZZI", "izzi"),
    ]

    // MARK: Category hints

    /// Keyword → chip. Checked against the merchant name and the top rows.
    /// More specific phrases (`UBER EATS`) are listed before general ones
    /// (`UBER`) — the first hit wins.
    static let categoryKeywords: [(phrase: String, category: ExpenseCategory)] = [
        // Food-delivery brands beat their ride-hailing parents.
        ("UBER EATS", .food), ("DIDI FOOD", .food), ("RAPPI", .food),
        // Coffee
        ("STARBUCKS", .coffee), ("TIM HORTONS", .coffee), ("PUNTA DEL CIELO", .coffee), ("CIELITO", .coffee),
        ("DUTCH BROS", .coffee), ("PEET S", .coffee), ("CAFE", .coffee), ("CAFETERIA", .coffee),
        ("COFFEE", .coffee), ("ESPRESSO", .coffee), ("LATTE", .coffee), ("CAPPUCCINO", .coffee),
        ("CAPUCHINO", .coffee), ("BARISTA", .coffee), ("TOSTADOR", .coffee), ("ROASTERS", .coffee),
        // Transit
        ("UBER", .transit), ("DIDI", .transit), ("LYFT", .transit), ("PEMEX", .transit),
        ("GASOLINERA", .transit), ("GASOLINA", .transit), ("GAS STATION", .transit), ("MAGNA", .transit),
        ("DIESEL", .transit), ("CHEVRON", .transit), ("SHELL", .transit),
        ("ARCO", .transit), ("MOBIL", .transit), ("ESTACIONAMIENTO", .transit), ("PARKING", .transit),
        ("PENSION", .transit), ("PEAJE", .transit), ("CASETA", .transit), ("TOLL", .transit),
        ("TAXI", .transit), ("METRO", .transit), ("AUTOBUS", .transit), ("CAMION", .transit),
        ("BUS", .transit), ("TROLLEY", .transit), ("AMTRAK", .transit), ("SENTRI", .transit),
        // Food (restaurants, delivery, groceries, convenience)
        ("RESTAURANT", .food), ("RESTAURANTE", .food), ("TAQUERIA", .food), ("TACOS", .food),
        ("PIZZA", .food), ("SUSHI", .food), ("BURGER", .food), ("HAMBURGUESA", .food), ("MCDONALD", .food),
        ("DOMINO", .food), ("KFC", .food), ("SUBWAY", .food), ("CHIPOTLE", .food), ("VIPS", .food),
        ("TOKS", .food), ("SANBORNS", .food), ("MARISCOS", .food), ("COCINA", .food), ("COMIDA", .food),
        ("FONDA", .food), ("BIRRIA", .food), ("POLLO", .food), ("CARNITAS", .food), ("PANADERIA", .food),
        ("TORTILLERIA", .food), ("ABARROTES", .food), ("SUPER", .food), ("MERCADO", .food),
        ("MARKET", .food), ("GROCERY", .food), ("OXXO", .food), ("7 ELEVEN", .food), ("CIRCLE K", .food),
        ("WALMART", .food), ("WAL MART", .food), ("BODEGA AURRERA", .food), ("SORIANA", .food),
        ("COSTCO", .food), ("HEB", .food), ("H E B", .food), ("CHEDRAUI", .food), ("CALIMAX", .food),
        ("SMART FINAL", .food), ("CASA LEY", .food), ("LA COMER", .food), ("TRADER JOE", .food),
        ("ALDI", .food), ("KROGER", .food), ("VONS", .food), ("RALPHS", .food), ("SAFEWAY", .food),
        ("WHOLE FOODS", .food), ("SPROUTS", .food), ("BAR", .food), ("CANTINA", .food), ("CERVECERIA", .food),
        ("PANDA EXPRESS", .food), ("TACO BELL", .food), ("WENDY", .food), ("CARL S JR", .food),
        ("IN N OUT", .food), ("EL POLLO LOCO", .food), ("LITTLE CAESARS", .food), ("PIZZA HUT", .food),
        // Shopping
        ("AMAZON", .shopping), ("LIVERPOOL", .shopping), ("COPPEL", .shopping), ("ELEKTRA", .shopping),
        ("SUBURBIA", .shopping), ("SEARS", .shopping), ("ZARA", .shopping), ("H M", .shopping),
        ("TARGET", .shopping), ("HOME DEPOT", .shopping), ("BEST BUY", .shopping), ("APPLE STORE", .shopping),
        ("IKEA", .shopping), ("ROSS", .shopping), ("MARSHALLS", .shopping), ("TJ MAXX", .shopping),
        ("NIKE", .shopping), ("ADIDAS", .shopping), ("FARMACIA", .shopping), ("FARMACIAS", .shopping),
        ("PHARMACY", .shopping), ("CVS", .shopping), ("WALGREENS", .shopping), ("RITE AID", .shopping),
        ("OFFICE DEPOT", .shopping), ("OFFICEMAX", .shopping), ("STAPLES", .shopping),
        ("BOUTIQUE", .shopping), ("MALL", .shopping),
        ("CINEPOLIS", .shopping), ("CINEMEX", .shopping), ("AMC", .shopping),
    ]

    /// Custom words handed to Vision so label vocabulary is recognised
    /// even on faded thermal paper.
    static let recognitionCustomWords: [String] = [
        "TOTAL", "SUBTOTAL", "IVA", "IEPS", "EFECTIVO", "CAMBIO", "PROPINA", "IMPORTE", "TARJETA", "PAGO",
        "MXN", "USD", "OXXO", "FOLIO", "TICKET", "CAJA", "RFC", "GRACIAS", "ARTICULOS", "DESCUENTO",
    ]
}
