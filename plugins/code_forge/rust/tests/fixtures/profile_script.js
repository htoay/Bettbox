const ruleOptionsEnable = {
  ai: true,
  streaming: true,
  ads: false,
};

const serviceConfigs = [
  { key: 'ai', name: 'AI', icon: 'ai.png', rules: ['DOMAIN-SUFFIX,ai.example,AI'] },
  { key: 'streaming', name: 'Streaming', icon: 'tv.png', rules: ['DOMAIN-SUFFIX,video.example,Streaming'] },
  { key: 'ads', name: 'Ads', rules: ['DOMAIN-KEYWORD,adservice,REJECT'] },
];

const Compatible_With_Bettbox = {
  policyGroupOptions: ['AI', 'Streaming', 42],
};

const regions = new Map([
  ['HK', '🇭🇰'],
  ['JP', '🇯🇵'],
]);

function decorate(name) {
  const match = /^(?<region>[A-Z]{2})\b/.exec(name);
  const flag = regions.get(match?.groups?.region) ?? '🏳️';
  return `${flag} ${name}`;
}

function main(config) {
  const proxies = (config.proxies ?? [])
    .filter((proxy) => !/expire/i.test(proxy.name))
    .map((proxy) => ({ ...proxy, name: decorate(proxy.name) }));
  const names = [...new Set(proxies.map((proxy) => proxy.name))];
  const enabled = serviceConfigs.filter((service) => ruleOptionsEnable[service.key]);
  console.log('enabled services', enabled.map((service) => service.name));

  return {
    ...config,
    proxies,
    'proxy-groups': [
      { name: 'Main', type: 'select', proxies: [...names, 'DIRECT'] },
      ...enabled.map((service) => ({ name: service.name, type: 'select', proxies: ['Main', ...names] })),
    ],
    rules: [...enabled.flatMap((service) => service.rules), ...config.rules.filter((rule) => rule.startsWith('GEOIP')), 'MATCH,Main'],
    dns: { ...config.dns, 'nameserver-policy': { ...config.dns?.['nameserver-policy'], '+.internal': 'system://' } },
  };
}
