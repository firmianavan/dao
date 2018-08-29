module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  // networks: {
  //   dev: {
  //     host: '127.0.0.1',
  //     port: '8545',
  //     network_id: '*'
  //   }
  // }
  //测试节点：47.52.114.83
// 节点端口：4138
// 测试账户："0x5f4e0074292ea1fa57d4dc819ce0fda820c3ccc7"
// 账户密码：123456
  networks: {
    tn: {
      host: '127.0.0.1',
      port: '7545',
      network_id: '5777'
    }
  }
};
