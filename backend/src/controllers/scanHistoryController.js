const ScanHistory = require('../models/ScanHistory');

/**
 * Save or update a product scan in user's history
 * POST /api/scan-history
 */
const saveScan = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const {
      productName,
      brand = '',
      barcode = '',
      imageUrl = '',
      score = 85,
      ingredients = '',
      allergens = [],
      nutrients = {},
    } = req.body;

    if (!productName || typeof productName !== 'string' || productName.trim() === '') {
      return res.status(400).json({
        success: false,
        status: 400,
        message: 'Product name is required to save a scan.',
      });
    }

    const cleanName = productName.trim();
    const cleanBrand = (brand || '').trim();
    const cleanBarcode = (barcode || '').trim();
    const cleanImage = (imageUrl || '').trim();

    // Check for existing scan entry for this user to avoid unbounded duplicate rows
    let existingScan = null;
    if (cleanBarcode) {
      existingScan = await ScanHistory.findOne({ userId, barcode: cleanBarcode });
    }
    if (!existingScan && cleanName) {
      existingScan = await ScanHistory.findOne({
        userId,
        productName: { $regex: new RegExp(`^${cleanName.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')}$`, 'i') },
        ...(cleanBrand ? { brand: { $regex: new RegExp(`^${cleanBrand.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')}$`, 'i') } } : {}),
      });
    }

    let savedScan;
    const now = new Date();

    if (existingScan) {
      existingScan.scannedAt = now;
      if (cleanImage) existingScan.imageUrl = cleanImage;
      if (cleanBrand) existingScan.brand = cleanBrand;
      if (cleanBarcode && !existingScan.barcode) existingScan.barcode = cleanBarcode;
      if (score !== undefined && score !== null) existingScan.score = score;
      if (ingredients) existingScan.ingredients = ingredients;
      if (Array.isArray(allergens) && allergens.length > 0) existingScan.allergens = allergens;
      if (nutrients && Object.keys(nutrients).length > 0) {
        existingScan.nutrients = {
          ...existingScan.nutrients,
          ...nutrients,
        };
      }
      savedScan = await existingScan.save();
    } else {
      savedScan = await ScanHistory.create({
        userId,
        productName: cleanName,
        brand: cleanBrand,
        barcode: cleanBarcode,
        imageUrl: cleanImage,
        score: score ?? 85,
        ingredients,
        allergens: Array.isArray(allergens) ? allergens : [],
        nutrients: nutrients || {},
        scannedAt: now,
      });
    }

    console.log('\n==============================================');
    console.log('[SCAN HISTORY SAVE]');
    console.log(`userId = ${userId}`);
    console.log(`productName = ${savedScan.productName}`);
    console.log(`productId/barcode = ${savedScan.barcode || 'N/A'}`);
    console.log(`timestamp = ${savedScan.scannedAt ? savedScan.scannedAt.toISOString() : now.toISOString()}`);
    console.log('==============================================\n');

    return res.status(200).json({
      success: true,
      message: 'Product scan saved to history successfully.',
      data: {
        scan: savedScan,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve scan history for authenticated user (ordered newest -> oldest)
 * GET /api/scan-history
 */
const getScanHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : null;

    let query = ScanHistory.find({ userId }).sort({ scannedAt: -1 });
    if (limit && !isNaN(limit) && limit > 0) {
      query = query.limit(limit);
    }

    const [scans, totalCount] = await Promise.all([
      query.exec(),
      ScanHistory.countDocuments({ userId }),
    ]);

    if (limit && limit <= 10) {
      console.log('\n==============================================');
      console.log('[HOME RECENT SCANS]');
      console.log(`userId = ${userId}`);
      console.log(`historyCount = ${scans.length}`);
      console.log(`latestScan = ${scans.length > 0 ? scans[0].productName : 'None'}`);
      console.log('==============================================\n');
    }

    console.log('\n==============================================');
    console.log('[SCAN HISTORY]');
    console.log(`userId = ${userId}`);
    console.log(`totalHistoryCount = ${totalCount}`);
    console.log('==============================================\n');

    return res.status(200).json({
      success: true,
      data: {
        scans,
        totalCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a single scan item
 * DELETE /api/scan-history/:id
 */
const deleteScan = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const scanId = req.params.id;

    const result = await ScanHistory.findOneAndDelete({ _id: scanId, userId });
    if (!result) {
      return res.status(404).json({
        success: false,
        status: 404,
        message: 'Scan history entry not found or unauthorized.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Scan removed from history successfully.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Clear all scan history for the user
 * DELETE /api/scan-history
 */
const clearScanHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;

    await ScanHistory.deleteMany({ userId });

    return res.status(200).json({
      success: true,
      message: 'Scan history cleared successfully.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  saveScan,
  getScanHistory,
  deleteScan,
  clearScanHistory,
};
