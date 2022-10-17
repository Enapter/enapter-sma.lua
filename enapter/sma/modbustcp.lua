local SmaModbusTcp = {}

function SmaModbusTcp.new(addr, unit_id)
  assert(type(addr) == 'string', 'addr (arg #1) must be string, given: '..inspect(addr))
  assert(type(unit_id) == 'number', 'unit_id (arg #2) must be number, given: '..inspect(unit_id))

  local self = setmetatable({}, { __index = SmaModbusTcp })
  self.addr = addr
  self.unit_id = unit_id
  return self
end

function SmaModbusTcp:connect()
  self.modbus = modbustcp.new(self.addr)
end

function SmaModbusTcp:read_holdings(address, number)
  assert(type(address) == 'number', 'address (arg #1) must be number, given: '..inspect(address))
  assert(type(number) == 'number', 'number (arg #1) must be number, given: '..inspect(number))

  local registers, err = self.modbus:read_holdings(self.unit_id, address, number, 1000)
  if err and err ~= 0 then
    enapter.log('read error: '..err, 'error')
    if err == 1 then
      -- Sometimes timeout happens and it may break underlying Modbus client,
      -- this is a temporary workaround which manually reconnects.
      self:connect()
    end
    return nil
  end

  return registers
end

function SmaModbusTcp:read_u32(address)
  local reg = self:read_holdings(address, 2)
  if not reg then return end

  -- NaN for U32 values
  if reg[1] == 0xFFFF and reg[2] == 0xFFFF then
    return nil
  end

  -- NaN for ENUM values
  if reg[1] == 0x00FF and reg[2] == 0xFFFD then
    return nil
  end

  local raw = string.pack('>I2I2', reg[1], reg[2])
  return string.unpack('>I4', raw)
end

function SmaModbusTcp:read_u32_enum(address)
  return self:read_u32(address)
end

function SmaModbusTcp:read_u32_fix0(address)
  return self:read_u32(address)
end

function SmaModbusTcp:read_u32_fix1(address)
  local v = self:read_u32(address)
  if v then
    return v / 10
  else
    return v
  end
end

function SmaModbusTcp:read_u32_fix2(address)
  local v = self:read_u32(address)
  if v then
    return v / 100
  else
    return v
  end
end

function SmaModbusTcp:read_u32_fix3(address)
  local v = self:read_u32(address)
  if v then
    return v / 1000
  else
    return v
  end
end

function SmaModbusTcp:read_s32(address)
  local reg = self:read_holdings(address, 2)
  if not reg then return end

  if reg[1] == 0x8000 and reg[2] == 0 then
    return nil
  end

  local raw = string.pack('>I2I2', reg[1], reg[2])
  return string.unpack('>i4', raw)
end

function SmaModbusTcp:read_s32_fix0(address)
  return self:read_s32(address)
end

function SmaModbusTcp:read_s32_fix1(address)
  local v = self:read_s32(address)
  if v then
    return v / 10
  else
    return v
  end
end

function SmaModbusTcp:read_s32_fix2(address)
  local v = self:read_s32(address)
  if v then
    return v / 100
  else
    return v
  end
end

function SmaModbusTcp:read_s32_fix3(address)
  local v = self:read_s32(address)
  if v then
    return v / 1000
  else
    return v
  end
end

return SmaModbusTcp
