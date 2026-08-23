const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  saveScan,
  getScanHistory,
  deleteScan,
  clearScanHistory,
} = require('../controllers/scanHistoryController');

// All scan history routes require valid JWT authentication
router.use(protect);

router.post('/', saveScan);
router.get('/', getScanHistory);
router.delete('/:id', deleteScan);
router.delete('/', clearScanHistory);

module.exports = router;
