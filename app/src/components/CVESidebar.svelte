<script>
  export let name = "";
  export let show = false;
  let old_name = "";

  const baseURL = "HOST";

  const baseAPIURL = `${baseURL}/api/v0`;
  let promise = Promise.resolve([]);

  $: if (old_name === "" || old_name != name) {
    old_name = name;
    promise = getCVEList(name);
  }

  function handleCloseBtn() {
    show = !show;
  }
  async function getCVEList(n) {
    let fetchURL = new URL(`${baseAPIURL}/cves`);
    let params = {
      name: n,
    };
    Object.keys(params).forEach((key) =>
      fetchURL.searchParams.append(key, params[key]),
    );

    const resp = await fetch(fetchURL);
    if (resp.ok) {
      return resp.json();
    } else {
      throw new Error("Invalid Response.");
    }
  }
  promise = getCVEList(name);
</script>

<style>
</style>

{#if show}
  <nav class="sidebar">
    <div class="sidebar-header">
      <p>
        <button class="btn btn-success" on:click={handleCloseBtn}>
          Close
        </button>
      </p>
      <h3 class="bg-title">{name}</h3>
      {#await promise}
        <p>{''}</p>
      {:then data}
        {#each data.data as cve}
          <div class="card">
            <div class="card-header">[{cve.status}]{cve.name}</div>
            <div class="card-body">{cve.description}</div>
          </div>
        {/each}
      {:catch error}
        <p style="color: red">{error.message}</p>
      {/await}
    </div>
  </nav>
{/if}
