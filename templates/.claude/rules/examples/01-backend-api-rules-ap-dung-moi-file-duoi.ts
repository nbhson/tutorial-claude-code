  // Luôn trả shape này, không trả string trần hay stack trace ra client
  return res.status(400).json({ code: "VALIDATION_ERROR", message: "email sai định dạng", requestId: req.id });
