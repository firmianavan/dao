pragma solidity 0.4.24;

/// @dev Models a address -> uint mapping where it is possible to iterate over all keys.
/// modified from https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol
library IterableMapping
{
    struct itmap{
        mapping(address => IndexValue) data;
        KeyFlag[] keys;
        uint size;
    }
    struct IndexValue { uint keyIndex; uint value; }
    struct KeyFlag { address key; bool deleted; }
    function insert(itmap storage self, address key, uint value) internal returns (bool replaced){
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0){
            return true;
        } else {
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }
    function get(itmap storage self, address key)internal view returns(uint) {
        return self.data[key].value;
    }
    function incr(itmap storage self, address key, uint delta) internal {
        require(self.data[key].value + delta >= self.data[key].value);
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value += delta;
        if (keyIndex == 0){
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
        }
    }
    function decr(itmap storage self, address key, uint delta) internal {
        require(self.data[key].value >= delta);
        if (self.data[key].value - delta == 0){
            remove(self,key);
        }
        self.data[key].value -= delta;
    }
    function remove(itmap storage self, address key) internal returns (bool success){
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0){
            return false;
        }
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }
    function contains(itmap storage self, address key) internal view returns (bool){
        return self.data[key].keyIndex > 0;
    }
    function iterate_start(itmap storage self) internal view returns (uint keyIndex){
        return iterate_next(self, uint(-1));
    }
    function iterate_valid(itmap storage self, uint keyIndex) internal view returns (bool){
        return keyIndex < self.keys.length;
    }
    function iterate_next(itmap storage self, uint keyIndex) internal view returns (uint r_keyIndex){
        uint t = keyIndex+1;
        while (t < self.keys.length && self.keys[t].deleted){
            t++;
        }
        return t;
    }
    function iterate_get(itmap storage self, uint keyIndex) internal view returns (address key, uint value){
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    /// @dev 分页查询 TODO 验证此时返回的不定长数组是否可以
    function iterate_limit(itmap storage self,uint from, uint len) internal view returns (address[] addrs, uint[] vals, uint to, bool isDone){
        uint j = 0;
        uint i = iterate_next(self, from-1);
        isDone = true;
        for (; iterate_valid(self, i); i = iterate_next(self, i)){
            if (i >= from+len){
                isDone = false;
                break;
            }
            (address key, uint value) = iterate_get(self, i);
            addrs[j] = key;
            vals[j] = value;
            j++;
        }
        to = i;
    }
}