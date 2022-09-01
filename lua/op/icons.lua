local M = {}

M.category_icons = {
  ['LOGIN'] = '',
  ['PASSWORD'] = '',
  ['API_CREDENTIAL'] = '',
  ['SERVER'] = '',
  ['DATABASE'] = '',
  ['CREDIT_CARD'] = '',
  ['MEMBERSHIP'] = '',
  ['PASSPORT'] = '',
  ['SOFTWARE_LICENSE'] = '',
  ['OUTDOOR_LICENSE'] = '',
  ['SECURE_NOTE'] = '',
  ['WIRELESS_ROUTER'] = '',
  ['BANK_ACCOUNT'] = '',
  ['DRIVER_LICENSE'] = '',
  ['IDENTITY'] = '',
  ['REWARD_PROGRAM'] = '',
  ['DOCUMENT'] = '',
  ['EMAIL_ACCOUNT'] = '',
  ['SOCIAL_SECURITY_NUMBER'] = '',
  ['MEDICAL_RECORD'] = '',
  ['SSH_KEY'] = '',
  ['CUSTOM'] = '',
}

function M.category_icon(category)
  return M.category_icons[category or 'CUSTOM'] or M.category_icons['CUSTOM']
end

return M
